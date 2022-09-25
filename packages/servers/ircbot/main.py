import os
import sys
import justirc
import json
import importlib

class EventHandler(object):
    def on_message(bot, event):
        ...

    def on_reload(bot):
        ...

def main():
    default_config = dict(
        debug=False,
        nick='smith',
        channel='#general',
        server='irc.privatevoid.net',
        port=6697,
        tls=True,
    )
    config = dict()
    if (config_file := os.getenv("IRCBOT_CONFIG")) and config_file != "":
        with open(config_file) as f:
            config = json.load(f)
    run_bot(default_config | config)

def shutdown_bot_hooks(bot):
    for name, hook in bot.hooks:
        try:
            hook.EventHandler.on_reload(bot)
        except Exception as e:
            print(f'exception running hook {name}: {e}')

def run_bot(c):
    bot = justirc.IRCConnection()

    bot.db = ()    # TODO: store a database handle here
    bot.hooks = [] # storage for all bot hooks

    if c['debug']:
        @bot.on('packet')
        def new_packet(e):
            print(e.packet)

    @bot.on('reload-hooks')
    def reload_hooks(e):
        shutdown_bot_hooks(bot)
        bot.hooks.clear()

        for path in filter(lambda h: h[-3:] == '.py', os.listdir('hooks')):
            name = '.'.join(['hooks', path[:-3]])
            if name in sys.modules.keys():
                del sys.modules[name]
            try:
                mod = importlib.import_module(name, package=name)
                bot.hooks.append((name, mod))
            except Exception as e:
                print(f'failed to load hook {name}: {e}')

    @bot.on('quit')
    def quit(e):
        shutdown_bot_hooks(bot)
        exit(0)

    @bot.on('connect')
    def connect(e):
        bot.send_line(f'NICK {c["nick"]}')
        bot.send_line(f'USER {c["nick"]} 8 * {c["nick"]}')
        bot.emit('reload-hooks')

    @bot.on('welcome')
    def welcome(e):
        bot.join_channel(c['channel'])

    @bot.on('message')
    def message(e):
        for name, hook in bot.hooks:
            try:
                hook.EventHandler.on_message(bot, e)
            except Exception as e:
                print(f'exception running hook {name}: {e}')

    bot.connect(c['server'], port=c['port'], tls=c['tls'])
    bot.run_loop()

if __name__ == '__main__':
    main()
