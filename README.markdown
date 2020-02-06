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

Se sei impaziente allora potresti provare con Play-With-Docker

[![Try in PWD](https://raw.githubusercontent.com/play-with-docker/stacks/master/assets/images/button.png)](https://labs.play-with-docker.com/?stack=https://raw.githubusercontent.com/amusarra/docker-apache-ssl-tls-mutual-authentication/master/docker-compose.yml)


![](images/iconfinder_note.png)
Il progetto è stato realizzato su macOS Mojave 10.14.4 e testato su Docker Desktop 
CE (versione 2.0.0.3) e Docker (Engine) 18.09.2. Per l'installazione su ambienti
Microsoft Windows consiglio la lettura di [Install Docker Desktop for Windows](https://docs.docker.com/docker-for-windows/install/).

## 1 - Overview
Questo è un progetto [docker](https://www.docker.com/) che parte dall'immagine 
base di [*ubuntu:18.04*](https://hub.docker.com/_/ubuntu), specializzato per 
soddisfare i requisiti minimi per un sistema di mutua autenticazione SSL/TLS.

Il software di base installato è:

* Apache HTTP 2.4 (2.4.29)
* PHP 7 (7.2.10-0ubuntu0.18.04.1)
* PHP 7 FPM (FastCGI Process Manager)

_L'installazione di PHP e del modulo per Apache è del tutto opzionale_. I due 
moduli sono stati installati esclusivamente per costruire la pagina di atterraggio
dell'utente dopo la fase di autenticazione. Questa pagina mostra una serie 
d'informazioni base estratte dal certificato digitale utilizzato per 
l'autenticazione.

La mutua autenticazione basata sul protocollo SSL/TLS si riferisce a due parti 
che si autenticano reciprocamente attraverso la verifica del certificato 
digitale fornito in modo che entrambe i partecipanti siano sicuri 
dell'identità altrui.

Da un punto di vista di alto livello, il processo di autenticazione e creazione 
di un canale crittografato utilizzando l'autenticazione reciproca (o mutua 
autenticazione) basata su certificati prevede i passaggi seguenti:

1. Un client richiede l'accesso a una risorsa protetta;
2. Il server presenta il suo certificato al client;
3. Il client verifica il certificato del server;
4. Se ha successo, il client invia il suo certificato al server;
5. Il server verifica le credenziali del cliente;
6. In caso di esito positivo, il server concede l'accesso alla risorsa protetta richiesta dal client.

In Figura 1 è mostrato quello che accade durante il processo di autenticazione 
reciproca (o mutua autenticazione).

![Cosa succede durante il processo di autenticazione reciproca](images/security-sslBMAWithCertificates.gif)

**Figura 1 - Cosa succede durante il processo di autenticazione reciproca (immagine da https://docs.oracle.com)**


## 2 - Struttura del Docker File
Cerchiamo di capire quali sono le sezioni più significative del Dockerfile. 
La prima riga del file (come anticipato in precedenza) fa in modo che il 
container parta dall'immagine docker *ubuntu:18.04*.

```docker
FROM ubuntu:18.04
```

A seguire c'è la sezione delle variabili di ambiente che sono prettamente 
specifiche di Apache HTTP. I valori di queste variabili d'ambiente possono
essere modificate in base alle proprie esigenze.

```docker
# General Apache ENVs
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
ENV APACHE_SSL_SSL_PROXY_ENGINE Off
ENV APACHE_SSL_PROXY_CHECK_PEER_NAME On
ENV APACHE_SERVER_SIGNATURE Off
ENV APACHE_SERVER_TOKENS Prod
ENV APACHE_HTTP_HEADER_X_POWERED_BY "Apache HTTP 2.4 for SSL/TLS Mutual Authentication (Ver. ${VERSION} - Git URL: ${VCS_URL} - Git Ref: ${VCS_REF})"

# For more info See https://httpd.apache.org/docs/2.4/mod/mod_http2.html
ENV APACHE_HTTP_PROTOCOLS http/1.1

# Specifics env Apache for application 
ENV APPLICATION_URL https://${APACHE_SERVER_NAME}:${APACHE_SSL_PORT}
ENV CLIENT_VERIFY_LANDING_PAGE /error.php

# Reverse Proxy Application
ENV APACHE_PROXY_PRESERVE_HOST On
ENV API_BASE_PATH /secure/api
ENV API_BACKEND_BASE_URL http://127.0.0.1:8000${API_BASE_PATH}
```

Il primo gruppo di quattro variabili sono molto esplicative e non necessitano 
approfondimenti. Le variabili a seguire e in particolare 
`APACHE_SSL_CERTS` e `APACHE_SSL_PRIVATE` impostano:

1. il nome del file che contiene il certificato pubblico del server in formato PEM;
2. il nome del file che contiene la chiave privata (in formato PEM) del certificato pubblico.

Il certificato server utilizzato in questo progetto è stato rilasciato da una
_Certification Authority_ privata create ad hoc e ovviamente non riconosciuta. 
Il CN (Common Name) di questo specifico certificato è impostato 
a **tls-auth.dontesta.it** rilasciato dalla _Antonio Musarra's Blog Certification Authority_.

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

La variabile `APACHE_HTTP_PROTOCOLS` specifica l'elenco di protocolli supportati 
per il server/host virtuale. L'elenco determina i protocolli consentiti che un 
cliente può negoziare per questo server/host.

È necessario impostare i protocolli se si desidera estendere i protocolli 
disponibili per un server/host. Per impostazione predefinita, è consentito solo 
il protocollo **http/1.1** (che include la compatibilità con i client 1.0 e 0.9).

I protocolli validi sono http/1.1 per le connessioni **http** e **https**, 
**h2** sulle connessioni https e **h2c** per le connessioni http.

Per maggiorni informazioni consultare la documentazione 
[Apache Module mod_http2](https://httpd.apache.org/docs/2.4/mod/mod_http2.html).

La sezione a seguire del Dockerfile contiene tutte le direttive necessarie per 
l'installazione del software indicato in precedenza. Dato che la distribuzione scelta 
è [**Ubuntu**](https://www.ubuntu.com/), il comando *apt* è responsabile della gestione 
dei package, quindi dell'installazione.

```docker
# Install services, packages and do cleanup
RUN apt update \
    && apt install -y apache2 \
    && apt install -y php php7.2-fpm \
    && apt install -y curl \
    && apt install -y python3-pip \
    && apt install -y git \
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

La sezione a seguire del Dockerfile esegue le seguenti principali attività:

1. abilita il modulo SSL
2. abilita il modulo headers
3. abilita il modulo MPM Worker
4. abilita il modulo HTTP2
5. abilita i moduli Proxy, Proxy HTTP e Proxy FCGI (Fast CGI) 
6. abilita il site ssl di default con la configurazione per la mutua autenticazione
7. abilita delle opzioni di configurazione al fine di rafforzare la sicurezza SSL/TLS
8. esegue il re-hash dei certificati. Operazione necessaria affinché Apache sia in grado di leggere i nuovi certificati

```docker
RUN a2enmod ssl \
    && a2enmod headers \
    && a2enmod rewrite \
    && a2dismod mpm_prefork \
    && a2dismod mpm_event \
    && a2enmod mpm_worker \
    && a2enmod proxy_fcgi \
    && a2enmod http2 \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod remoteip \
    && a2ensite default-ssl \
    && a2enconf ssl-params \
    && a2enconf php7.2-fpm \
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
|    |   └── mrossi.dontesta.it.req
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

La directory *configs* contiene al suo interno altre folder e file, 
in particolare:

1. **certs**
    * contiene il certificato del server (chiave pubblica, chiave privata e CSR);
    * contiene il certificato della CA (chiave pubblica e chiave privata);
    * contiene il certificato client personale per l'autenticazione tramite browser. Sono disponibili: chiave pubblica, chiave privata, CSR, coppia di chiavi in formato PKCS#12;
    * contiene il certificato client da utilizzare per autenticare un'applicazione o dispositivo. Sono disponibili: chiave pubblica, chiave privata, CSR, coppia di chiavi in formato PKCS#12;
2. **openssl**: contiene il file di configurazione per il tool openssl con le impostazioni predefinite;
3. **httpd**: contiene tutte le configurazioni di Apache necessarie per abilitare la mutua autenticazione;
4. **www**: contiene una semplice interfaccia web;
5. **scripts**: contiene l'entrypoint script che avvia il server Apache

## 4 - Quickstart
L'immagine di questo progetto docker è disponibile sul mio account docker hub
[amusarra/apache-ssl-tls-mutual-authentication](https://hub.docker.com/r/amusarra/apache-ssl-tls-mutual-authentication).

A seguire il comando per il **pull** dell'immagine docker ospitata su docker hub. 
Il primo comando esegue il pull dell'ultima versione (tag latest), mentre il 
secondo comando esegue il pull della specifica versione dell'immagine che in 
questo caso è la versione 1.0.0.

```bash
docker pull amusarra/apache-ssl-tls-mutual-authentication
docker pull amusarra/apache-ssl-tls-mutual-authentication:1.0.0
```
Una volta eseguito il pull dell'immagine docker (versione 1.0.0) è possibile 
creare il nuovo container tramite il comando a seguire.

```bash
docker run -i -t -d -p 10443:10443 --name=apache-ssl-tls-mutual-authentication amusarra/apache-ssl-tls-mutual-authentication:1.0.0
```

Utilizzando il comando `docker ps` dovremmo poter vedere in lista il nuovo
container, così come indicato a seguire.

```bash
CONTAINER ID        IMAGE                                  COMMAND                  CREATED             STATUS              PORTS                      NAMES
bb707fb00e89        amusarra/apache-ssl-tls-mutual-authentication:1.0.0   "/usr/sbin/apache2ct…"   6 seconds ago       Up 4 seconds        0.0.0.0:10443->10443/tcp   apache-ssl-tls-mutual-authentication
```

Nel caso in cui vogliate apportare delle modifiche al Dockerfile, dovreste poi 
procedere con la build della nuova immagine e al termine eseguire il run 
dell'immagine ottenuta. A seguire sono indicati i comandi *docker* da eseguire 
dal proprio terminale.

_I comandi docker di build e run devono essere eseguiti dalla root della directory 
di progetto dopo aver fatto il clone di questo repository._

```bash
docker build -t apache-ssl-tls-mutual-authentication .
docker run -i -t -d -p 10443:10443 --name=apache-ssl-tls-mutual-authentication apache-ssl-tls-mutual-authentication:latest
```

A questo punto sul nostro sistema dovremmo avere la nuova immagine con il 
nome **apache-ssl-tls-mutual-authentication** e in esecuzione il nuovo container chiamato
**apache-ssl-tls-mutual-authentication**. Per ragioni di comodità ho chiamato il container
con lo stesso nome dell'immagine, nessuno però vieta di assegnare un nome diverso. 

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

Da questo momento è possibile raggiungere il servizio di mutua autenticazione 
SSL/TLS utilizzando il browser. 

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

La password di entrambe i PKCS#12 è impostata a: **secret**. Questa è la password
da utilizzare per importare i certificati.

```
Subject: C=IT, L=Rome, ST=Italy, O=Mario Rossi S.r.l, OU=Horse Club, CN=mario.rossi@horseclubsample.com/emailAddress=admin@horseclubsample.com

Subject: C=IT, L=Bronte, ST=Italy, O=Judio Horse Club, OU=IT Services, CN=tls-client.dontesta.it/emailAddress=info@dontesta.it
```

I due certificati sono stati rilasciati dalla CA **Antonio Musarra's Blog Certification Authority**. 
A seguire i dettagli della CA che ha rilasciato tutti i certificati disponibili
all'interno del progetto.

```
Issuer: C=IT, L=Rome, ST=Italy, O=Antonio Musarra's Blog, OU=IT Security Department, CN=Antonio Musarra's Blog Certification Authority/emailAddress=info@dontesta.it
```

Una volta installato il certificato client (file con estensione .p12) sul proprio 
browser (per esempio Firefox), è possibile eseguire il test di mutua autenticazione 
tramite certificato. 

La Figura 2 mostra il certificato digitale installato sul browser Firefox. 
Questo è il certificato da utilizzare per l'autenticazione.

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


Accedendo agli _access log_ di Apache è possibile notare due informazioni utili 
al tracciamento delle operazioni eseguite dall'utente:

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

![Pagina di errore in caso di certificato non valido](images/CertificateValidationError.png)

**Figura 6 - Pagina di errore in caso di certificato non valido**


## 5 - Build, Run e Push docker image via Makefile
Al fine di semplificare le operazioni di _build_, _run_ e _push_ dell'immagine docker, 
è stato introdotto il [Makefile](https://github.com/amusarra/docker-apache-ssl-tls-mutual-authentication/blob/develop/Makefile).

Per utilizzare il Makefile occorre che sulla propria macchina siano installati
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
utilizzando il tool [OpenSSL](https://openssl.org). Tutti i comandi a seguire sono
stati e devono eventualmente essere eseguiti dalla root del progetto. I comandi
hanno l'obiettivo di:

1. Creare la propria Certificate Authority;
2. Creare la chiave privata del certificato server e **CSR (Certificate Signing Request)**;
3. Firmare il certificato server da parte della CA (creata in precedenza);
4. Creare le chiavi private per i certificati client;
5. Creare le CSR per i certificati client;
6. Firmare i certificati client da parte della CA;
7. Esportare la coppia di chiavi in formato PKCS#12.

1 - Creazione della propria Certificate Authority
```
$ openssl req -config ./configs/openssl/openssl.cnf -newkey rsa -nodes \
	-keyform PEM -keyout ./configs/certs/blog.dontesta.it.ca.key \
	-x509 -days 3650 -extensions certauth \
	-outform PEM -out ./configs/certs/blog.dontesta.it.ca.cer
```

2 - Creazione della chiave privata del certificato server e CSR
```
$ openssl genrsa -out ./configs/certs/tls-auth.dontesta.it.key 4096
$ openssl req -config ./configs/openssl/openssl.cnf -new \
	-key ./configs/certs/tls-auth.dontesta.it.key \
	-out ./configs/certs/tls-auth.dontesta.it.req
```

2 - Firma del certificato server da parte della CA
```
$ openssl x509 -req -in ./configs/certs/tls-auth.dontesta.it.req -sha512 \
	-CA ./configs/certs/blog.dontesta.it.ca.cer \
	-CAkey ./configs/certs/blog.dontesta.it.ca.key \
	-set_serial 100 -extfile ./configs/openssl/openssl.cnf \
	-extensions server -days 735 \
	-outform PEM -out ./configs/certs/tls-auth.dontesta.it.cer
```
Dalla versione 1.2.2 del progetto, i certificati del server sono stati aggiornati
con certificati rilasciati da Let's Encrypt (via (ZeroSSL)[https://zerossl.com/])

A seguire i comandi OpenSSL utilizzati per creare i certificati client.

3 - Creazione delle chiavi private
```
$ openssl genrsa -out ./configs/certs/tls-client.dontesta.it.key 4096
$ openssl genrsa -out ./configs/certs/mrossi.dontesta.it.key 4096
```

4 - Creazione delle CSR
```
$ openssl req -config ./configs/openssl/openssl.cnf \
	-new -key ./configs/certs/tls-client.dontesta.it.key \
	-out ./configs/certs/tls-client.dontesta.it.req

$ openssl req -config ./configs/openssl/openssl.cnf \
	-new -key ./configs/certs/mrossi.dontesta.it.key \
	-out ./configs/certs/mrossi.dontesta.it.req
```

5 - Firma dei certificati client da parte della CA
```
$ openssl x509 -req -in ./configs/certs/tls-client.dontesta.it.req -sha512 \
	-CA ./configs/certs/blog.dontesta.it.ca.cer \
	-CAkey ./configs/certs/blog.dontesta.it.ca.key \
	-set_serial 200 -extfile ./configs/openssl/openssl.cnf \
	-extensions client -days 365 \
	-outform PEM -out ./configs/certs/tls-client.dontesta.it.cer

$ openssl x509 -req -in ./configs/certs/mrossi.dontesta.it.req -sha512 \
	-CA ./configs/certs/blog.dontesta.it.ca.cer \
	-CAkey ./configs/certs/blog.dontesta.it.ca.key \
	-set_serial 400 -extfile ./configs/openssl/openssl.cnf \
	-extensions client -days 365 -outform PEM \
	-out ./configs/certs/mrossi.dontesta.it.cer
```

6 - Esportazione della coppia di chiavi in formato PKCS#12
```
$ openssl pkcs12 -export -inkey ./configs/certs/tls-client.dontesta.it.key \
	-in ./configs/certs/tls-client.dontesta.it.cer \
	-out ./configs/certs/tls-client.dontesta.it.p12

$ openssl pkcs12 -export -inkey ./configs/certs/mrossi.dontesta.it.key \
	-in ./configs/certs/mrossi.dontesta.it.cer \
	-out ./configs/certs/mrossi.dontesta.it.p12
```

## 8 - Come abilitare il protocollo HTTP2
Dalla versione 1.1.0 del progetto, è possibile attivare il protocollo [HTTP/2 (RFC 7540)](https://tools.ietf.org/html/rfc7540).

Attivare il protocollo HTTP/2 (H2 SSL/TLS) è davvero semplice, basta eseguire il
_run_ dell'immagine impostando le seguenti due varibili con i valori indicati
di seguito.

1. APACHE_SSL_VERIFY_CLIENT=require
2. APACHE_HTTP_PROTOCOLS=h2 http/1.1

Il comando mostrato esegue il run dell'immagine impostando le due variabili
di ambiente che consentono l'attivazione del protocollo HTTP/2.

```
docker run -i -t -d -p 10443:10443 \
	-e APACHE_SSL_VERIFY_CLIENT='require' \
	-e APACHE_HTTP_PROTOCOLS='h2 http/1.1' \
	--name=apache-ssl-tls-mutual-authentication \
	amusarra/apache-ssl-tls-mutual-authentication:1.1.0
```
La figura a seguire illustra l'utilizzo del protocollo HTTP/2 (H2-TLS) invece del protocollo
HTTP/1.1 (TLS).

![Abilitazione protocollo HTTP/2 su Apache 2.4](images/Apache2.4_HTTP2_Enabled.png)

**Figura 7 - Abilitazione protocollo HTTP/2 su Apache 2.4**

## 9 - Integrazione del progetto httpbin
Dalla versione 1.2.0 del progetto è stato introdotto [httpbin](https://github.com/postmanlabs/httpbin.git), progetto realizzato da [Kenneth Reitz](http://kennethreitz.org/bitcoin).

[httpbin](https://github.com/postmanlabs/httpbin.git) è un progetto che implementa
un semplice servizio di richiesta e risposta basato sul protocollo HTTP.

Ho deciso d'integrare questo progetto al fine di facilitare i test di accesso tramite
mutua autenticazione verso servizi REST.

La variabile d'ambiente `API_BASE_PATH` definisce il _base path_ dei servizi REST
offerti dal progetto **httpbin** a cui è possibile accedere esclusivamente attraverso una
mutua autenticazione.

Puntando il proprio browser all'indirizzo [https://tls-auth.dontesta.it:10443/secure/api](https://tls-auth.dontesta.it:10443/secure/api) e dopo aver eseguito l'autenticazione, dovremmo ottenere l'interfaccia di [Swagger](https://swagger.io)
che mostra la lista dei servizi disponibili e che possiamo richiamare direttamente dal browser. La figura a seguire mostra l'interfaccia di Swagger.

![Visualizzazione Swagger UI](images/httpbin_swagger_ui.png)

**Figura 8 - Visualizzazione Swagger UI e servizi REST esposti da httpbin**

Per ottenere il descrittore dei servizi REST in formato swagger 2.0, è sufficiente
scaricare il documento json [spec.json](https://tls-auth.dontesta.it:10443/secure/api/spec.json). Il descrittore può essere per esempio importato su [Postman](https://www.getpostman.com/) per poi testare i servizi REST in **muta autenticazione**. 

![Esempio di chiamata a servizio REST via Swagger UI](images/httpbin_swagger_ui_call_api.png)

**Figura 9 - Esempio di chiamata a servizio REST via Swagger UI**

Prima di poter eseguire il test con Postman:

1. Il certificato server è di tipo _self-signed_, occorre quindi impostare a __off__ il controllo dei certificati SSL/TLS (vedi figura 10). Questo evita di ottenere l'errore in fase di connessione al servizio;
2. Importare il certificato client (vedi figura 11). È possibile utilizzare il certificato di esempio **tls-client.dontesta.it.cer** in dotazione con il progetto.

![Disattivazione verifica SSL](images/postman_setting_ssl_1.png)

**Figura 10 - Disattivazione verifica SSL**

Postman richiede il file _cer_ e _key_ al fine di poter aggiungere il certificato
client. La password da utilizzare è: **secret**

![Aggiunta del certificato client per la muta autenticazione](images/postmain_add_client_cert.png)

**Figura 11 - Aggiunta del certificato client per la muta autenticazione**

La figura a seguire mostra un esempio di chiamata al servizio **/secure/api/get**.
Da notare gli http header `X-Client-Dn` e `X-Client-Verify`, che rispettivamente
mostrano il DN (Distinguished Name) del certificato client presentato in fase di
autenticazione e l'esito del processo di autenticazione, in questo caso **SUCCESS**.

![Esempio di chiamata ad uno dei servizi di httpbin](images/postman_rest_call_1.png)

**Figura 12 - Esempio di chiamata ad uno dei servizi di httpbin**


## 10 - Conclusioni
Credo che questo progetto possa essere utile a coloro che hanno la necessità di
realizzare un servizio di mutua autenticazione SSL/TLS e non sanno magari
da dove iniziare. **Questo progetto potrebbe essere quindi un buon punto di partenza.**

Ogni suggerimento e/o segnalazione di bug è gradito; consiglio eventualmente di 
aprire una [issue](https://github.com/amusarra/docker-apache-ssl-tls-mutual-authentication/issues)

## Project License
The MIT License (MIT)

Copyright &copy; 2020 Antonio Musarra's Blog - [https://www.dontesta.it](https://www.dontesta.it "Antonio Musarra's Blog"), 
[antonio.musarra@gmail.com](mailto:antonio.musarra@gmail.com "Antonio Musarra Email")

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.