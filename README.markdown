# Apache HTTP 2.4 - Docker image for SSL/TLS Mutual Authentication
[![Antonio Musarra's Blog](https://img.shields.io/badge/maintainer-Antonio_Musarra's_Blog-purple.svg?colorB=6e60cc)](https://www.dontesta.it)
[![Build Status](https://travis-ci.org/amusarra/docker-apache-ssl-tls-mutual-authentication.svg?branch=master)](https://travis-ci.org/amusarra/docker-apache-ssl-tls-mutual-authentication)
[![](https://images.microbadger.com/badges/image/amusarra/apache-ssl-tls-mutual-authentication.svg)](https://microbadger.com/images/amusarra/apache-ssl-tls-mutual-authentication "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/amusarra/apache-ssl-tls-mutual-authentication.svg)](https://microbadger.com/images/amusarra/apache-ssl-tls-mutual-authentication "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/amusarra/apache-ssl-tls-mutual-authentication.svg)](https://microbadger.com/images/amusarra/apache-ssl-tls-mutual-authentication "Get your own commit badge on microbadger.com")
[![Twitter Follow](https://img.shields.io/twitter/follow/antonio_musarra.svg?style=social&label=%40antonio_musarra%20on%20Twitter&style=plastic)](https://twitter.com/antonio_musarra)

L'obiettivo di questo progetto è quello di fornire un **template** pronto all'uso
e che realizza un sistema di **mutua autenticazione o autenticazione bilaterale SSL/TLS** 
basato su [Apache HTTP](http://httpd.apache.org/docs/2.4/). 
**Ognuno è libero poi di modificare o specializzare questo progetto sulla base delle proprie esigenze**

## 1 - Overview
Questo è un progetto [docker](https://www.docker.com/) che parte dall'immagine base di [*ubuntu:18.04*](https://hub.docker.com/_/ubuntu), specializzato per soddisfare i requisiti minimi per un sistema di mutua autenticazione SSL/TLS.

Il software di base installato è:

* Apache HTTP 2.4 (2.4.29)
* PHP 7 (7.2.10-0ubuntu0.18.04.1)
* Modulo PHP per Apache

_L'installazione di PHP e del modulo per Apache è del tutto opzionale_. I due 
moduli sono stati installati esclusivamente per costruire la pagina di atterraggio
dell'utente dopo la fase di autenticazione. Questa pagina mostra una serie d'informazioni
base estratte dal certificato digitale utilizzato per l'autenticazione.

La mutua autenticazione basata sul protocollo SSL/TLS si riferisce a due parti che si autenticano
reciprocamente attraverso la verifica del certificato digitale fornito in modo che entrambe i 
partecipanti siano sicuri dell'identità altrui.

Da un punto di vista di alto livello, il processo di autenticazione e creazione di un canale 
crittografato utilizzando l'autenticazione reciproca (o mutua autenticazione) basata su certificati 
prevede i passaggi seguenti:

1. Un client richiede l'accesso a una risorsa protetta;
2. Il server presenta il suo certificato al client;
3. Il client verifica il certificato del server;
4. Se ha successo, il client invia il suo certificato al server;
5. Il server verifica le credenziali del cliente;
6. In caso di esito positivo, il server concede l'accesso alla risorsa protetta richiesta dal client.

In Figura 1 è mostrato quello che accade durante il processo di autenticazione reciproca (o
mutua autenticazione).

![Cosa succede durante il processo di autenticazione reciproca](images/security-sslBMAWithCertificates.gif)

**Figura 1 - Cosa succede durante il processo di autenticazione reciproca (immagine da https://docs.oracle.com)**


## 2 - Struttura del Docker File
Cerchiamo di capire quali sono le sezioni più significative del Dockefile. 
La prima riga del file (come anticipato in precedenza) fa in modo che il 
container parta dall'immagine docker *ubuntu:18.04*.

```docker
FROM ubuntu:18.04
```

A seguire c'è la sezione delle variabili di ambiente che sono prettamente 
specifiche di Apache HTTP. I valori di queste variabili d'ambiente possono
essere modificate in base alle proprie esigenze.

```docker
# Apache ENVs
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_SERVER_NAME tls-auth.dontesta.it
ENV APACHE_SERVER_ADMIN tls-auth@dontesta.it
ENV APACHE_SSL_CERTS tls-auth.dontesta.it.cer 
ENV APACHE_SSL_PRIVATE tls-auth.dontesta.it.key
ENV APACHE_SSL_PORT 10443
ENV APACHE_LOG_LEVEL info
ENV APACHE_SSL_LOG_LEVEL info
ENV APACHE_SSL_VERIFY_CLIENT optional
ENV APPLICATION_URL https://${APACHE_SERVER_NAME}:${APACHE_SSL_PORT}
ENV CLIENT_VERIFY_LANDING_PAGE /error.php
```

Il primo gruppo delle quattro variabili sono molto esplicative e non necessitano approfondimenti.
Le variabili a seguire e in particolare `APACHE_SSL_CERTS` e `APACHE_SSL_PRIVATE` impostano:

1. il nome del file che contiene il certificato pubblico del server in formato PEM;
2. il nome del file che contiene la chiave privata (in formato PEM) del certificato pubblico.

Il certificato server utilizzato in questo progetto è stato rilasciato da una
_Certification Authority_ privata (non riconosciuta). Il CN (Common Name) di questo specifico certificato 
è impostato a **tls-auth.dontesta.it**.

Di default la porta *HTTPS* è impostata a **10443** dalla variabile `APACHE_SSL_PORT`.
La variabile `APPLICATION_URL` definisce il path di redirect qualora si accedesse 
via protocollo HTTP e non HTTPS.

Le variabili `APACHE_LOG_LEVEL`e `APACHE_SSL_LOG_LEVEL`, consentono di modificare
il livello log generale e quello specifico per il modulo SSL. Il valore di default
è impostato a INFO. Per maggiori informazioni potete consultare la documentazione su
[LogLevel Directive](https://httpd.apache.org/docs/2.4/mod/core.html#loglevel).

La variabile `APACHE_SSL_VERIFY_CLIENT` agisce sulla configurazione del processo
di verifica del certificato lato client. Il valore di default è impostato a **optional**.
Rendere opzionale la verifica, consente una gestione più flessibile dell'errore 
in caso che la validazione del certificato client fallisse.

Nel caso in cui il valore della direttiva di Apache **SSLVerifyClient** sia 
**optional** o **optional_no_ca**, se dovesse accadere qualche errore di validazione,
allora sarebbe visualizzata la specifica pagina definita dalla variabile 
`CLIENT_VERIFY_LANDING_PAGE`.

La sezione a seguire del Dockerfile, contiene tutte le direttive necessarie per 
l'installazione del software indicato in precedenza. Dato che la  distribuzione scelta 
è [**Ubuntu**](https://www.ubuntu.com/), il comando *apt* è responsabile della gestione 
dei package, quindi dell'installazione.

```docker
# Install services, packages and do cleanup
RUN apt update \
    && apt install -y apache2 \
    && apt install -y php libapache2-mod-php \
    && apt install -y curl \
    && apt install -y python \
    && rm -rf /var/lib/apt/lists/*
```
 
La sezione a seguire del Dockerfile, anch'essa esplicativa, copia le 
configurazioni di Apache opportunamente modificate al fine di abilitare 
la mutua autenticazione.

```docker
# Copy Apache configuration file
COPY configs/httpd/000-default.conf /etc/apache2/sites-available/
COPY configs/httpd/default-ssl.conf /etc/apache2/sites-available/
COPY configs/httpd/ssl-params.conf /etc/apache2/conf-available/
COPY configs/httpd/dir.conf /etc/apache2/mods-enabled/
COPY configs/httpd/ports.conf /etc/apache2/
```

La sezione a seguire del Dockerfile, copia la coppia di chiavi del server 
e il certificato pubblico della CA.

```docker
# Copy Server (pub and key) tls-auth.dontesta.it
# Copy CA (Certification Authority) Public Key
COPY configs/certs/blog.dontesta.it.ca.cer /etc/ssl/certs/
COPY configs/certs/tls-auth.dontesta.it.cer /etc/ssl/certs/
COPY configs/certs/tls-auth.dontesta.it.key /etc/ssl/private/
``` 

La sezione a seguire del Dockerfile, copia tre script PHP a scopo di test sulla 
*document root* standard di Apache.

```docker
# Copy php samples script and other
COPY configs/www/*.php /var/www/html/
COPY configs/www/assets /var/www/html/assets
COPY configs/www/secure /var/www/html/secure
COPY images/favicon.ico /var/www/html/favicon.ico
```

La sezione a seguire del Dockerfile copia lo script di entrypoint che avvia
server Apache HTTP.

```docker
# Copy scripts and entrypoint
COPY scripts/entrypoint /entrypoint
```

La sezione a seguire del Dockerfile esegue le seguenti attività:

1. abilita il modulo SSL
2. abilita il modulo headers
3. abilita il site ssl di default con la configurazione per la mutua autenticazione
4. abilita delle opzioni di configurazione al fine di rafforzare la sicurezza SSL/TLS
5. esegue il re-hash dei certificati. Operazione necessaria affinché Apache sia in grado di leggere i nuovi certificati

```docker
RUN a2enmod ssl \
    && a2enmod headers \
    && a2enmod rewrite \
    && a2ensite default-ssl \
    && a2enconf ssl-params \
    && c_rehash /etc/ssl/certs/
```

Le due ultime direttive indicate sul Dockerfile, dichiarano la porta HTTPS 
(`APACHE_SSL_PORT`) che deve essere pubblicata e il comando da eseguire per mettere 
in listen (o ascolto) il nuovo servizio Apache HTTP.

## 3 - Organizzazione
In termini di directory e file, il progetto è organizzato così come mostrato a 
seguire. Il cuore di tutto è la directory **configs**.

```
├── Dockerfile
├── configs
│    ├── certs
│    │   ├── blog.dontesta.it.ca.cer
│    │   ├── blog.dontesta.it.ca.key
|    |   ├── tls-auth.dontesta.it.cer
|    |   ├── tls-auth.dontesta.it.key
|    |   ├── tls-auth.dontesta.it.req
|    |   ├── tls-client.dontesta.it.cer
|    |   ├── tls-client.dontesta.it.key
|    |   ├── tls-client.dontesta.it.p12
|    |   ├── tls-client.dontesta.it.req
|    |   ├── mrossi.dontesta.it.cer
|    |   ├── mrossi.dontesta.it.key
|    |   ├── mrossi.dontesta.it.p12
|    |   ├── mrossi.dontesta.it.req
│    ├── httpd
│    │   ├── 000-default.conf
│    │   ├── default-ssl.conf
│    │   ├── dir.conf
│    │   ├── ports.conf
│    │   └── ssl-params.conf
│    ├── openssl
│    │   └── openssl.cnf
│    └── wwww
└── scripts
    └── entrypoint
```

La directory *configs* contiene al suo interno altre folder e file, in particolare:

1. **certs**
    * contiene il certificato del server (chiave pubblica, chiave privata e CSR);
    * contiene il certificato della CA (chiave pubblica e chiave privata);
    * contiene il certificato client personale per l'autenticazione tramite browser. Sono disponibili: chiave pubblica, chiave privata, CSR, coppia di chiavi in formato PKCS#12;
    * contiene il certificato client da utilizzare per autenticare un applicazione o dispositivo. Sono disponibili: chiave pubblica, chiave privata, CSR, coppia di chiavi in formato PKCS#12;
2. **openssl**: contiene il file di configurazione per il tool openssl;
3. **httpd**: contiene tutte le configurazioni di Apache necessarie per abilitare la mutua autenticazione;
4. **www**: contiene una semplice interfaccia web;
5. **scripts**: contiene l'entrypoint script che avvia il server Apache

## 4 - Quickstart
L'immagine di questo progetto docker è disponibile sull'account docker hub
[amusarra/apache-ssl-tls-mutual-authentication](https://hub.docker.com/r/amusarra/apache-ssl-tls-mutual-authentication).

A seguire il comando per il pull dell'immagine docker ospitata su docker hub. Il primo comando 
esegue il pull dell'ultima versione (tag latest), mentre il secondo comando esegue 
il pull della specifica versione dell'immagine, in questo caso la versione 1.0.0.

```bash
docker pull amusarra/apache-ssl-tls-mutual-authentication
docker pull amusarra/apache-ssl-tls-mutual-authentication:1.0.0
```
Una volta eseguito il pull dell'immagine docker (versione 1.0.0) è possibile creare il nuovo
container tramite il comando a seguire.

```bash
docker run -i -t -d -p 10443:10443 --name=apache-ssl-tls-mutual-authentication amusarra/apache-ssl-tls-mutual-authentication:1.0.0
```
Utilizzando il comando `docker ps` dovremmo poter vedere in lista il nuovo
container, così come indicato a seguire.

```bash
CONTAINER ID        IMAGE                                  COMMAND                  CREATED             STATUS              PORTS                      NAMES
bb707fb00e89        amusarra/apache-ssl-tls-mutual-authentication:1.0.0   "/usr/sbin/apache2ct…"   6 seconds ago       Up 4 seconds        0.0.0.0:10443->10443/tcp   apache-ssl-tls-mutual-authentication
```

Nel caso in cui vogliate apportare delle modifiche dovreste poi procedere con 
la build della nuova immagine e al termine lanciare l'immagine ottenuta. 
A seguire sono indicati i comandi *docker* da eseguire dal proprio terminale.

_I comandi docker di build e run devono essere eseguiti dalla root della directory 
di progetto dopo aver fatto il clone di questo repository._

```bash
docker build -t apache-ssl-tls-mutual-authentication .
docker run -i -t -d -p 10443:10443 --name=apache-ssl-tls-mutual-authentication apache-ssl-tls-mutual-authentication:latest
```

A questo punto sul nostro sistema dovremmo avere la nuova immagine con il 
nome **apache-ssl-tls-mutual-authentication** e in esecuzione il nuovo container chiamato
**apache-ssl-tls-mutual-authentication**. Per ragioni di comodità ho chiamato il container
con lo stesso nome dell'immagine, nessun però vieta di assegnare un nome diverso. 

Utilizzando il comando `docker images` dovremmo poter vedere in lista la nuova
immagine, così come indicato a seguire.

```
REPOSITORY                                      TAG                 IMAGE ID            CREATED             SIZE
apache-ssl-tls-mutual-authentication                           latest              1a145475d1f1        30 minutes ago      242MB
```

Utilizzando il comando `docker ps` dovremmo poter vedere in lista il nuovo
container, così come indicato a seguire.

```
CONTAINER ID        IMAGE                          COMMAND                  CREATED             STATUS              PORTS                      NAMES
65c874216624        apache-ssl-tls-mutual-authentication:latest   "/usr/sbin/apache2ct…"   36 minutes ago      Up 36 minutes       0.0.0.0:10443->10443/tcp   apache-ssl-tls-mutual-authentication
```

Da questo momento è possibile raggiungere il servizio di mutua autenticazione SSL/TLS 
utilizzando il browser. 

Per evitare l'errore `SSL_ERROR_BAD_CERT_DOMAIN` da parte del browser accedendo 
al servizio tramite la URL https://127.0.0.1:10443/, bisogna aggiungere al proprio
file di _hosts_ la riga a seguire.

```
##
# Servizio di mutua autenticazione via Apache HTTPD
##
127.0.0.1       tls-auth.dontesta.it
```

In ambiente di collaudo e/o produzione il nome del servizio o FQDN sarà registrato 
su un DNS.

Lato **server-side** è tutto pronto, manca però una configurazione **client side**,
ovvero, l'installazione del certificato digitale personale sul proprio browser. All'interno
del progetto ho reso disponibili due certificati di esempio che possono essere utilizzati
come certificati client, in particolare:

1. mrossi.dontesta.it.p12
2. tls-client.dontesta.it.p12

Il primo è un certificato digitale _personale_, invece, il secondo certificato digitale può
essere utilizzato per autenticare un'applicazione. Entrambe i certificati (quindi la coppia 
di chiavi) sono contenuti all'interno di un PKCS#12. A seguire sono mostrati i subject dei
rispettivi certificati.

```
Subject: C=IT, L=Rome, ST=Italy, O=Mario Rossi S.r.l, OU=Horse Club, CN=mario.rossi@horseclubsample.com/emailAddress=admin@horseclubsample.com

Subject: C=IT, L=Bronte, ST=Italy, O=Judio Horse Club, OU=IT Services, CN=tls-client.dontesta.it/emailAddress=info@dontesta.it
```
I due certificati sono stati rilasciati dalla Certification Authority **Antonio Musarra's Blog**. A seguire
i dettagli.

```
Issuer: C=IT, L=Rome, ST=Italy, O=Antonio Musarra's Blog, OU=IT Security Department, CN=Antonio Musarra's Blog Certification Authority/emailAddress=info@dontesta.it
```
Una volta installato il certificato client (file con estensione .p12) sul proprio 
browser (per esempio Firefox), è possibile eseguire il test di autenticazione 
tramite certificato. 

La Figura 2 mostra il certificato digitale installato sul browser Firefox. Questo è il certificato da
utilizzare per l'autenticazione.

![Certificato Digitale Personale installato sul browser](images/InstalledDigitalPersonalCertified.png)

**Figura 2 - Installazione del certificato digitale personale sul browser Firefox**

Puntando all'indirizzo [https://tls-auth.dontesta.it:10443](https://tls-auth.dontesta.it:10443) dovrebbe accadere quanto segue:

1. Cliccare sul pulsante _Login_ o _LOGIN WITH YOUR DIGITAL CERTIFICATE_
2. Selezionare il certificato digitale installato in precedenza
3. Visualizzazione della pagina di benvenuto.

Le immagini a seguire mostrano il risultato dei tre step precedentemente indicati.

![Welcome Page di Accesso](images/WelcomePageToAccessViaClientCertificate.png)

**Figura 3 - Welcome Page di accesso tramite certificato client**

![Selezione certificato](images/SelectClientCertificate.png)

**Figura 4 - Selezione del certificato client**

![Welcome Page dopo accesso](images/WelcomePageAfterSuccessAuth.png)

**Figura 5 - Welcome Page dopo accesso avvenuto con successo**


Accedendo agli access log di Apache è possibile notare queste due informazioni 
utili al tracciamento delle operazioni eseguite dall'utente:

* Il protocollo SSL
* Il valore della variabile SSL_CLIENT_S_DN_CN 

```log
172.17.0.1 TLSv1.2 - antonio.musarra@gmail.com [11/Apr/2019:20:17:53 +0000] "GET /secure/ HTTP/1.1" 200 4745 "https://tls-auth.dontesta.it:10443/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:66.0) Gecko/20100101 Firefox/66.0"
```

Il valore di `SSL_CLIENT_S_DN_CN` è inoltre impostato come **SSLUserName**, questo
fa in modo che la variabile `REMOTE_USER` sia impostata con il CN del certificato digitale 
che identifica univocamente l'utente. 

In caso di errore in fase di validazione del certificato client, viene mostrata la pagina
di errore visibile in Figura 6.

![Pagina di errore in caso di certificato non valito](images/CertificateValidationError.png)

**Figura 6 - Pagina di errore in caso di certificato non valito**


## 5 - Build, Run e Push docker image via Makefile
Al fine di semplificare le operazioni di build, run e push dell'immagine docker, 
è stato introdotto il [Makefile](https://github.com/amusarra/docker-apache-ssl-tls-mutual-authentication/blob/develop/Makefile).

Per utilizzare il Makefile, occorre che sulla propria macchina siano installati
correttamente i tools di build.

I target disponibili sono i seguenti:

1. **build**: Target di _default_ che esegue il build dell'immagine;
2. **debug**: Esegue la build dell'immagine e successivamente apre un shell bash sul container; 
3. **run**: Esegue la build dell'immagine e successivamente crea il container lanciando l'applicazione (Apache HTTPD 2.4);
4. **clean**: Esegue un prune delle immagini;
5. **remove**: Rimuove l'ultima immagine creata;
6. **release**: Esegue la build dell'imaggine e successivamente effettua il push su dockerhub.

É possibile eseguire il target _release_ solo sul branch master, inoltre, il push 
dell'immagine su DockerHub richiede l'accesso (via username e password) tramite 
il comando `docker login`.

## 6 - Come sono stati generati i certificati
Tutti i certificati di esempio disponibili all'interno del progetto sono stati generati
utilizzando il tool [OpenSSL](https://openssl.org).

Creazione della propria Certificate Authority
```
$ openssl req -config ./configs/openssl/openssl.cnf -newkey rsa:2048 -nodes \
-keyform PEM -keyout ./configs/certs/blog.dontesta.it.ca.key -x509 -days 3650 -extensions certauth -outform PEM -out ./configs/certs/blog.dontesta.it.ca.cer
```

Creazione della chiave privata del certificato server e CSR
```
$ openssl genrsa -out ./configs/certs/tls-auth.dontesta.it.key 2048
$ openssl req -config ./configs/openssl/openssl.cnf -new -key ./configs/certs/tls-auth.dontesta.it.key -out ./configs/certs/tls-auth.dontesta.it.req
```

Firma del certificato server da parte della CA
```
$ openssl x509 -req -in ./configs/certs/tls-auth.dontesta.it.req -CA ./configs/certs/blog.dontesta.it.ca.cer -CAkey ./configs/certs/blog.dontesta.it.ca.key \
-set_serial 100 -extfile ./configs/openssl/openssl.cnf -extensions server -days 365 -outform PEM -out ./configs/certs/tls-auth.dontesta.it.cer
```

A seguire i comandi OpenSSL utilizzati per creare i certificati client.

Creazione delle chiavi private
```
$ openssl genrsa -out ./configs/certs/tls-client.dontesta.it.key 2048
$ openssl genrsa -out ./configs/certs/mrossi.dontesta.it.key 2048
```

Creazione delle CSR
```
$ openssl req -config ./configs/openssl/openssl.cnf -new -key ./configs/certs/tls-client.dontesta.it.key -out ./configs/certs/tls-client.dontesta.it.req

$ openssl req -config ./configs/openssl/openssl.cnf -new -key ./configs/certs/mrossi.dontesta.it.key -out ./configs/certs/mrossi.dontesta.it.req
```

Firma dei certificati client da parte della CA
```
$ openssl x509 -req -in ./configs/certs/tls-client.dontesta.it.req -CA ./configs/certs/blog.dontesta.it.ca.cer -CAkey ./configs/certs/blog.dontesta.it.ca.key \
-set_serial 200 -extfile ./configs/openssl/openssl.cnf -extensions client -days 365 -outform PEM -out ./configs/certs/tls-client.dontesta.it.cer

$ openssl x509 -req -in ./configs/certs/mrossi.dontesta.it.req -CA ./configs/certs/blog.dontesta.it.ca.cer -CAkey ./configs/certs/blog.dontesta.it.ca.key \
-set_serial 400 -extfile ./configs/openssl/openssl.cnf -extensions client -days 365 -outform PEM -out ./configs/certs/mrossi.dontesta.it.cer
```

Esportazione della coppia di chiavi in formato PKCS#12
```
$ openssl pkcs12 -export -inkey ./configs/certs/tls-client.dontesta.it.key -in ./configs/certs/tls-client.dontesta.it.cer -out ./configs/certs/tls-client.dontesta.it.p12

$ openssl pkcs12 -export -inkey ./configs/certs/mrossi.dontesta.it.key -in ./configs/certs/mrossi.dontesta.it.cer -out ./configs/certs/mrossi.dontesta.it.p12
```

## 7 - Conclusioni
Credo che questo progetto possa essere utile a coloro che hanno la necessità di
realizzare un servizio di mutua autenticazione SSL/TLS e non sanno magari
da dove iniziare. **Questo progetto potrebbe essere quindi un buon punto di partenza.**

Ogni suggerimento e/o segnalazione di bug è gradito; consiglio eventualmente di 
aprire una [issue](https://github.com/amusarra/docker-apache-ssl-tls-mutual-authentication/issues)

## Project License
The MIT License (MIT)

Copyright &copy; 2018 Antonio Musarra's Blog - [https://www.dontesta.it](https://www.dontesta.it "Antonio Musarra's Blog"), 
[antonio.musarra@gmail.com](mailto:antonio.musarra@gmail.com "Antonio Musarra Email")

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

<span style="color:#D83410">
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
<span>
