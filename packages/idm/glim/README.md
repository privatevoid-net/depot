# Glim

Glim is a simple identity access management system that speaks some LDAP and is written in Go. Glim stands for Golang LDAP Identity Management 😄

## Why Glim

Why not? In my case I use several tools that require a user and password to get access. Sure, we could use our Google, Twitter, Github accounts, but some of those open source tools prefer the good old LDAP protocol to authenticate, manage groups and store account information.

It's remarkable that LDAP was designed a long time ago and it's still alive and kicking. We all should develop our protocols and software in a way that they can be useful for years.

I've used LDAP servers like OpenLDAP, ApacheDS and 389DS to run my directory and used CLI or Apache Directory Studio to manage it. All of these tools are serious projects and are the best tools available when you need real LDAP servers.

The fact is that when using LDAP for authentication I've found that:

- I don't usually need all the batteries included with those LDAP servers.
- You need more time to learn how to manage and maintain those servers.
- If you want to use CLI tools, you need some time to spend learning things like LDAP schemas or LDIF (LDAP Data Interchange Format).
- It's hard to find an open source LDAP server that offers a REST API.

Finally I decided to develop my own simple identity management system that can be used with LDAP bind operations for authentication purposes and stores my team users accounts and group information. I wanted that simple server to spoke enough LDAP for my authentication purposes.

If you're looking for a full LDAP server replacement that fully understands schemas or complex search filters, please use the serious battle-tested staff, but if you want a server that can:

- Answer LDAP authentication (bind) and search queries sent by your applications
- Store your users and groups in a SQL database (Postgres or SQLite)
- Manage your users and groups with simple CLI commands
- Provide a simple REST API that you can use with your applications
- Be used for your automated tests...

please try Glim and help me to improve it and visit the [wiki](https://github.com/doncicuto/glim/wiki) for more information about Glim (configuration examples, docker, advanced topics...)

## Try it with Docker 🐋

Please, visit the [wiki section](https://github.com/doncicuto/glim/wiki/Docker) about Docker, but in a nutshell follow these steps to run Glim with Docker:

1. Create a temp folder: `mkdir /tmp/glim`

2. Run a server using the following command: `docker run -e GLIM_API_SECRET="yourapisecret" -v /tmp/glim:/home/glim/.glim  --name glim -p 1323:1323 -p 1636:1636 -d sologitops/glim`

3. Check your logs and see the passwords that have been generated automatically:

```bash
docker logs -f glim

...
------------------------------------- WARNING -------------------------------------
A new user with manager permissions has been created:
- Username: admin
- Password Dg9FXUkrs6aOTqhMkKLW3ESvmsQvS4Bm6g12WAamQ9cbzRfxEdxpL7NEsOlyZax2
Please store or write down this password to manage Glim.
You can delete this user once you assign manager permissions to another user
-----------------------------------------------------------------------------------

------------------------------------- WARNING -------------------------------------
A new user with read-only permissions has been created:
- Username: search
- Password WgkJeRgAuRzdPncgj50f9TXAtN9NbGiAqDn8pRvlxW7vJetGeSy4zf2aMTEc1X4G
Please store or write down this password to perform search queries in Glim.
-----------------------------------------------------------------------------------
```

4. Open a terminal and play with Glim

```bash
docker exec -it glim /app/glim login
Username: admin
Password: 
Login Succeeded
```

## How does it work

```(bash)
$ GLIM_API_SECRET="mysecret" glim server start

> Glim starts a LDAP server (port 1636) and a REST API (port 1323).

$ glim login -u cedric.daniels
Password: 
Login Succeeded

$ glim user

UID    USERNAME        FULLNAME             EMAIL                GROUPS               MANAGER  READONLY LOCKED  
1      admin           LDAP administrator                        none                 true     false    false   
2      search                                                    none                 false    true     false   
3      cedric.daniels  Cedric Daniels       cedric.daniels@ba... none                 true     false    false   
4      kima.greggs     Kima Greggs          kima.greggs@balti... none                 false    false    false   
5      jimmy.mcnulty   Jimmy McNulty        jimmy.mcnulty@bal... none                 false    false    false

$ glim group create -n homicides -d "Homicides" -m jimmy.mcnulty,kima.greggs,cedric.daniels
Group created

$ glim group

GID    GROUP                DESCRIPTION                         MEMBERS                                           
1      homicides            Homicides Department                cedric.daniels, kima.greggs, jimmy.mcnulty

$ glim user create -u lester.freamon -e lester.freamon@baltimorepolice.org
Password:
Confirm password:
User created

$ glim user rm -u jimmy.mcnulty
User account deleted

$ LDAPTLS_CACERT=/home/cedric/.glim/ca.pem ldapwhoami -x -D "cn=admin,dc=example,dc=org" -W -H ldaps://127.0.0.1:1636
Enter LDAP Password:
dn:cn=admin,dc=example,dc=org 

$ glim logout

$ glim server stop
```

By default, Glim server will listen on 1323 TCP port (REST API) and on 1636 TCP (LDAPS) port and only TLS communications will be allowed in order to secure credentials and data exchange. You can set the IP address and port used for both servers using *--ldap-addr* and *--rest-addr*. If you start Glim with *--ldap-no-tls* you can disable tls encryption for Glim's LDAP server.

While I understand that you don't want to use certificates for testing, I feel that it is a good practice to use certificates from the beginning. Glim can create a fake CA and generate client and server certificates and matching private keys for testing purposes.

If you start the Glim server without specifying your CA and server certificates, Glim will create a fake CA and generate certificates for your operations that will be by default at $HOME/.glim.

When using the CLI a REST API will be consumed using TLS. You should use the --tlscacert flag to specify the path to your Root CA pem file or store it as ca.pem in the .glim directory at your user HOME directory. Failing to provide a valid CA pem file you'll receive the following error message:

```(bash)
Could not find required CA pem file to validate authority
```

## FAQ

1. Which applications can use Glim to authenticate users?

   > In theory Glim can be used with any application that use common methods to authenticate users with LDAP but so far Glim has been tested with: Gitea, Harbor, Portainer CE, Apache Guacamole, OpenNebula, Gitlab CE and Kanboard and you can find configuration examples in the wiki. If your application can't use Glim please let us know.

2. Is Glim a proxy for LDAP requests that can be sent to LDAP backends?

   > No. Glim stores users and groups in a SQL database (SQLite or Postgres).  

3. Can I add or delete users or groups using LDIF files?

   > No. You can use Glim's CLI to manage your users and groups easier.

4. Can I use phpLDAPadmin, Apache Directory Studio or other LDAP GUI tool?

   > Not currently. Glim cannot answer Root DSE requests or add/delete LDAP operations. Open a discussion if you find this feature useful so it can be added to the roadmap.

5. Does Glim support anonymous bind?

   > Nope. Glim comes with a search user (readonly) that you can use to bind and search information

6. Does Glim have a web user interface?

   > Not for now, but open a discussion if you need a web management tool that will use Glim's REST API.

## Limitations / Caveats

1. You can start and stop your Glim server using `glim server [start|stop]` but if you are running Glim on a Windows machine, the stop command will fail and you will have to stop it using Ctrl+C, this is due a limitation with signal handling in Windows. In a future version this behavior could be changed if I find a workaround for prospective Windows users.

2. Glim cannot reply to Root DSE requests, so you cannot use LDAP tools like Apache Directory Studio or phpLDAPadmin to browse or manage your directory.

3. Alias dereferencing in search requests is not supported.

### Acknowledgments

Many thanks to @johnweldon and all the contributors for [https://github.com/go-asn1-ber/asn1-ber](https://github.com/go-asn1-ber/asn1-ber).

Also, many thanks to @labstack for the [Echo framework](https://github.com/labstack/echo).
