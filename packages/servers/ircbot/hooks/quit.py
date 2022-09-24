import main

class EventHandler(main.EventHandler):
    def on_message(bot, e):
        if e.message == '.quit':
            bot.send_message(e.channel, 'exiting...')
            bot.emit('quit')
