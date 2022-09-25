import main

class EventHandler(main.EventHandler):
    def on_message(bot, e):
        if e.message == '.fistbump':
            msg = f'vroooooooooooo fiiiist, {e.sender}! :^)'
            bot.send_message(e.channel, msg)
