import justirc

def main():
    config = dict(nick='smith', debug=False)
    run_bot(config)

def run_bot(c):
    bot = justirc.IRCConnection()

    if c['debug']:
        @bot.on('packet')
        def new_packet(e):
            print(e.packet)

    @bot.on('connect')
    def connect(e):
        bot.send_line(f'NICK {c["nick"]}')
        bot.send_line(f'USER {c["nick"]} 8 * {c["nick"]}')

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
