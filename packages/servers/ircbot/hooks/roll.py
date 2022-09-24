import main
import random

class EventHandler(main.EventHandler):
    def on_message(bot, e):
        if e.message == '.roll':
            msg = f'{e.sender}: rolled a {random.randint(1, 6)}'
            bot.send_message(e.channel, msg)
