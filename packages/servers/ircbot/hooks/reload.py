import main

class EventHandler(main.EventHandler):
    def on_message(bot, e):
        if e.message == '.reload':
            bot.send_message(e.channel, 'reloading hooks...')
            bot.emit('reload-hooks')
