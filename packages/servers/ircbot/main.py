import justirc

NICK = 'smith'

def main():
    bot = justirc.IRCConnection()

    @bot.on('packet')
    def new_packet(e):
        print(e.packet)

    @bot.on('connected')
    def reload_plugins(e):
        print('bot has connected')

    @bot.on('connect')
    def connect(e):
        bot.send_line(f'NICK {NICK}')
        bot.send_line(f'USER {NICK} 8 * {NICK}')
        bot.emit('connected')

    @bot.on('welcome')
    def welcome(e):
        bot.join_channel("#general")

    @bot.on('message')
    def message(e):
        message = e.message.lower()
        if message == '.fistbump':
            message = f'vroooooooooooo fiiiist, {e.sender} :vvvv)))'
            bot.send_message(e.channel, message)

    bot.connect('irc.privatevoid.net', port=6697, tls=True)
    bot.run_loop()

if __name__ == '__main__':
    main()
