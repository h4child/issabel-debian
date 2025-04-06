#!/bin/bash

SOURCE_DIR_SCRIPT=$(pwd)

[[ -s issabel_var.env ]] || {
   echo "Please create y complete file issabel_var.env"
   exit 1
}
source issabel_var.env

#Add sbin to path
if ! grep -Pq 'export PATH=.*/usr/sbin.*' /etc/bash.bashrc; then
   echo "export PATH=$PATH:/usr/local/sbin:/usr/sbin" >> /etc/bash.bashrc
fi

if ! $(echo "$PATH" | grep -Fq "sbin") ; then
   echo -e "Error: /usr/sbin is not in PATH\n"
   echo -e "Run: source /etc/bash.bashrc \n"
   echo -e "and run ./install-issabel-debian.sh\n"
   exit 1
fi


# Enable non free and contrib repos
if ! grep -Pq '^(deb.+)main(.+)contrib non-free' /etc/bash.bashrc; then
   sed -i -E 's/^(deb.+)main(.+)/\1main contrib non-free\2/g' /etc/apt/sources.list
fi

#Updata and upgrade package
apt update
apt upgrade -y
apt install -y apt-transport-https lsb-release ca-certificates wget curl aptitude build-essential

#Uninstall apparmor
if service --status-all | grep -Fq 'apparmor'; then
   service apparmor stop
   apt remove -y apparmor
fi

#Package installation
apt install -y \
   git apache2 gettext sngrep\
   unixodbc odbcinst unixodbc-dev \
   mariadb-server mariadb-client \
   libmariadb-dev cockpit net-tools \
   dialog locales-all libwww-perl \
   mpg123 sox fail2ban  \
   cracklib-runtime dnsutils \
   certbot python3-certbot-apache \
   iptables libedit-dev uuid-dev \
   libxml2-dev libxml2 \
   sqlite3 libsqlite3-dev libsqlite3-0


#Add user asterisk
if ! id -u "asterisk" >/dev/null 2>&1; then
   adduser asterisk --uid 5000 --gecos "Asterisk PBX" --disabled-password --disabled-login --home /var/lib/asterisk
fi

#Download Asterisk
ASTERISK_SRC_DIR="$(basename $ASTERISK_SRC_FILE .tar.gz)"
ASTERISK_URL_DOWNLOAD=$ASTERISK_URL/$ASTERISK_SRC_FILE
if echo "$ASTERISK_SRC_FILE" | grep -Fq "certified" ; then
   ASTERISK_URL_DOWNLOAD=$ASTERISK_URL_CERTIFIED/$ASTERISK_SRC_FILE
fi


cd /usr/src
[[ -f $ASTERISK_SRC_FILE ]] || {
   wget $ASTERISK_URL_DOWNLOAD
}

[[ -d /usr/src/${ASTERISK_SRC_DIR} ]] || mkdir -p /usr/src/${ASTERISK_SRC_DIR}

tar zxf $ASTERISK_SRC_FILE -C /usr/src/${ASTERISK_SRC_DIR} --strip-components=1
cd ${ASTERISK_SRC_DIR}/

#Install Asterisk dependencies
./contrib/scripts/install_prereq install

#Install asterisk
./configure --with-jansson-bundled
make menuselect.makeopts 
menuselect/menuselect \
    --disable-category MENUSELECT_ADDONS \
    --disable app_flash \
    --disable app_skel \
    --disable-category MENUSELECT_CDR \
    --disable-category MENUSELECT_CEL \
    --disable cdr_pgsql \
    --disable cel_pgsql \
    --disable-category MENUSELECT_CHANNELS \
    --enable  chan_iax2 \
    --enable  chan_pjsip \
    --enable  chan_rtp \
    --enable-category MENUSELECT_CODECS \
    --enable-category MENUSELECT_FORMATS \
    --enable-category MENUSELECT_FUNCS \
    --enable-category  MENUSELECT_PBX \
    --enable app_macro \
    --enable  pbx_config \
    --enable pbx_loopback \
    --enable pbx_spool \
    --enable pbx_realtime \
    --enable res_agi \
    --enable res_ari \
    --enable res_ari_applications \
    --enable res_ari_asterisk \
    --enable res_ari_bridges \
    --enable res_ari_channels \
    --enable res_ari_device_states \
    --enable res_ari_endpoints \
    --enable res_ari_events \
    --enable res_ari_mailboxes \
    --enable res_ari_model \
    --enable res_ari_playbacks \
    --enable res_ari_recordings \
    --enable res_ari_sounds \
    --enable res_clialiases \
    --enable res_clioriginate \
    --enable res_config_curl \
    --enable res_config_odbc \
    --disable res_config_sqlite3 \
    --enable res_convert \
    --enable res_crypto \
    --enable res_curl \
    --enable res_fax \
    --enable res_format_attr_celt \
    --enable res_format_attr_g729 \
    --enable res_format_attr_h263 \
    --enable res_format_attr_h264 \
    --enable res_format_attr_ilbc \
    --enable res_format_attr_opus \
    --enable res_format_attr_silk \
    --enable res_format_attr_siren14 \
    --enable res_format_attr_siren7 \
    --enable res_format_attr_vp8 \
    --enable res_http_media_cache \
    --enable res_http_post \
    --enable res_http_websocket \
    --enable res_limit \
    --enable res_manager_devicestate \
    --enable res_manager_presencestate \
    --enable res_musiconhold \
    --enable res_mutestream \
    --enable res_mwi_devstate \
    --disable res_mwi_external \
    --disable res_mwi_external_ami \
    --disable res_odbc \
    --disable res_odbc_transaction \
    --enable res_parking \
    --enable res_pjproject \
    --enable res_pjsip \
    --enable res_pjsip_acl \
    --enable res_pjsip_authenticator_digest \
    --enable res_pjsip_caller_id \
    --enable res_pjsip_config_wizard \
    --enable res_pjsip_dialog_info_body_generator \
    --enable res_pjsip_diversion \
    --enable res_pjsip_dlg_options \
    --enable res_pjsip_dtmf_info \
    --enable res_pjsip_empty_info \
    --enable res_pjsip_endpoint_identifier_anonymous \
    --enable res_pjsip_endpoint_identifier_ip \
    --enable res_pjsip_endpoint_identifier_user \
    --enable res_pjsip_exten_state \
    --enable res_pjsip_header_funcs \
    --enable res_pjsip_logger \
    --enable res_pjsip_messaging \
    --enable res_pjsip_mwi \
    --enable res_pjsip_mwi_body_generator \
    --enable res_pjsip_nat \
    --enable res_pjsip_notify \
    --enable res_pjsip_one_touch_record_info \
    --enable res_pjsip_outbound_authenticator_digest \
    --enable res_pjsip_outbound_publish \
    --enable res_pjsip_outbound_registration \
    --enable res_pjsip_path \
    --enable res_pjsip_pidf_body_generator \
    --enable res_pjsip_pidf_digium_body_supplement \
    --enable res_pjsip_pidf_eyebeam_body_supplement \
    --enable res_pjsip_publish_asterisk \
    --enable res_pjsip_pubsub \
    --enable res_pjsip_refer \
    --enable res_pjsip_registrar \
    --enable res_pjsip_rfc3326 \
    --enable res_pjsip_sdp_rtp \
    --enable res_pjsip_send_to_voicemail \
    --enable res_pjsip_session \
    --enable res_pjsip_sips_contact \
    --enable res_pjsip_t38 \
    --enable res_pjsip_transport_websocket \
    --enable res_pjsip_xpidf_body_generator \
    --enable res_realtime \
    --enable res_resolver_unbound \
    --enable res_rtp_asterisk \
    --enable res_rtp_multicast \
    --enable res_security_log \
    --enable res_sorcery_astdb \
    --enable res_sorcery_config \
    --enable res_sorcery_memory \
    --enable res_sorcery_memory_cache \
    --enable res_sorcery_realtime \
    --enable res_speech \
    --enable res_srtp \
    --enable res_stasis \
    --enable res_stasis_answer \
    --enable res_stasis_device_state \
    --enable res_stasis_mailbox \
    --enable res_stasis_playback \
    --enable res_stasis_recording \
    --enable res_stasis_snoop \
    --enable res_stasis_test \
    --enable res_stun_monitor \
    --enable res_timing_dahdi \
    --enable res_timing_timerfd \
    --disable res_ael_share \
    --disable res_calendar \
    --disable res_calendar_caldav \
    --disable res_calendar_ews \
    --disable res_calendar_exchange \
    --disable res_calendar_icalendar \
    --disable res_chan_stats \
    --disable res_config_ldap \
    --enable res_config_pgsql \
    --disable res_corosync \
    --disable res_endpoint_stats \
    --disable res_fax_spandsp \
    --enable res_hep \
    --enable res_hep_pjsip \
    --enable res_hep_rtcp \
    --disable res_phoneprov \
    --disable res_pjsip_history \
    --disable res_pjsip_phoneprov_provider \
    --disable res_pktccops \
    --disable res_remb_modifier \
    --disable res_smdi \
    --disable res_snmp \
    --disable res_statsd \
    --enable res_timing_kqueue \
    --disable res_timing_pthread \
    --disable res_adsi \
    --enable res_config_sqlite3 \
    --disable res_monitor \
    --disable res_digium_phone \
    --disable res_mwi_external \
    --disable res_stasis_mailbox \
    --enable cdr_adaptive_odbc \
    --enable cdr_custom \
    --enable cdr_manager  \
    --enable cdr_csv \
    menuselect.makeopts

make
make install

tar zxf $SOURCE_DIR_SCRIPT/asterisk/asterisk_issabel.tar.gz -C /etc
rm -f /etc/asterisk/stir_shaken.conf

mkdir -p /var/lib/asterisk/sounds/es

#Set permisions to asterisk directories
chown -R asterisk: /etc/asterisk/
chown -R asterisk: /var/run/asterisk
chown -R asterisk: /var/log/asterisk
chown -R asterisk: /var/lib/asterisk

asterisk -g -n

/usr/bin/cp -rf $SOURCE_DIR_SCRIPT/script/login-info.sh /etc/profile.d/login-info.sh 
chmod 755 /etc/profile.d/login-info.sh

#Intall php7.4
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list 

apt update
apt-mark hold php8*

apt install -y \
   libapache2-mod-php7.4 php7.4-cli php7.4-common \
   php7.4-curl php7.4-json php7.4-mbstring \
   php7.4-mysql php7.4-opcache php7.4-readline \
   php7.4-sqlite3 php7.4-xml php7.4 php-pear

if [ -d /usr/lib/x86_64-linux-gnu/asterisk/modules ]; then
    mkdir /usr/lib/asterisk  
    ln -s /usr/lib/x86_64-linux-gnu/asterisk/modules /usr/lib/asterisk  
fi

rm /var/www/html/index.html

cat > /var/www/html/index.html <<EOF
<html>
<head>
<meta http-equiv="refresh" content="0; url=/admin">
</head>
<body></body>
</html>
EOF

# Apache Configuration
sed -i -e "s/www-data/asterisk/" /etc/apache2/envvars
echo "<Directory /var/www/html/pbxapi>" >/etc/apache2/conf-available/pbxapi.conf
echo "    AllowOverride All" >>/etc/apache2/conf-available/pbxapi.conf
echo "</Directory>" >>/etc/apache2/conf-available/pbxapi.conf
ln -s /etc/apache2/conf-available/pbxapi.conf /etc/apache2/conf-enabled  
a2enmod rewrite 

# Enable SSL
a2enmod ssl 
ln -s /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/  

#Restart apache
service apache2 restart  

# UnixODBC config
cat > /etc/odbc.ini <<EOF
[MySQL-asteriskcdrdb]
Description=MySQL connection to 'asteriskcdrdb' database
driver=MySQL ODBC 8.0 Unicode Driver
server=localhost
database=asteriskcdrdb
Port=3306
Socket=/var/lib/mysql/mysql.sock
option=3
Charset=utf8

[asterisk]
driver=MySQL ODBC 8.0 Unicode Driver
server=localhost
database=asterisk
Port=3306
Socket=/var/lib/mysql/mysql.sock
option=3
charset=utf8
EOF


# Install Maria ODBC Connector for some distros/versions
cd /usr/src
if [ -e "/run/mysqld/mysqld.sock" ]; then
	sed -i -e 's/Socket=\/var\/lib\/mysql\/mysql.sock/astdatadir => \/run\/mysqld\/mysqld.sock/' /etc/odbc.ini
elif [ -e "/var/run/mysqld/mysqld.sock" ]; then
	sed -i -e 's/Socket=\/var\/lib\/mysql\/mysql.sock/astdatadir => \/var\/lib\/mysql\/mysql.sock/' /etc/odbc.ini
fi

if [ -f /etc/lsb-release ]; then
    DLFILE="https://dlm.mariadb.com/1936476/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-ubuntu-focal-amd64.tar.gz"
elif [ -f /etc/debian_version ]; then
    if [ $(cat /etc/debian_version | cut -d. -f1) = 12 ]; then
        DLFILE="https://dlm.mariadb.com/1936451/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-debian-buster-amd64.tar.gz"
    elif [ $(cat /etc/debian_version | cut -d. -f1) = 11 ]; then
        DLFILE="https://dlm.mariadb.com/1936451/Connectors/odbc/connector-odbc-3.1.15/mariadb-connector-odbc-3.1.15-debian-buster-amd64.tar.gz"
    fi
fi

FILENAME=$(basename $DLFILE)
rm -rf $FILENAME 
wget $DLFILE  
tar zxf $FILENAME 
rm $FILENAME$A 
cp $(find /usr/src/ -name libmaodbc.so) /usr/local/lib 

cat > /etc/odbcinst.ini <<EOF
[MySQL ODBC 8.0 Unicode Driver]
Driver=/usr/local/lib/libmaodbc.so
UsageCount=1

[MySQL ODBC 8.0 ANSI Driver]
Driver=/usr/local/lib/libmaodbc.so
UsageCount=1
EOF

# IssabelPBX Installation
cd /usr/src
git clone https://github.com/asternic/issabelPBX.git

# IssabelPbx copy patch 
/usr/bin/cp -rf $SOURCE_DIR_SCRIPT/issabel/patch/*.patch /usr/src/issabelPBX

# IssabelPbx apply patch 
cd /usr/src/issabelPBX

for i in $(ls *.patch); do echo "Apply patch $i"; git apply $i; done

# Asterisk configs
sed -i '/^displayconnects/a #include manager_general_additional.conf' /etc/asterisk/manager.conf
sed -i '/^displayconnects/d' /etc/asterisk/manager.conf
sed -i 's/\/usr\/share/\/var\/lib/g' /etc/asterisk/asterisk.conf
touch /etc/asterisk/manager_general_additional.conf 
echo "displayconnects=yes" >/etc/asterisk/manager_general_additional.conf
echo "timestampevents=yes" >>/etc/asterisk/manager_general_additional.conf
echo "webenabled=no" >>/etc/asterisk/manager_general_additional.conf
chown asterisk: /etc/asterisk/manager_general_additional.conf 
chown asterisk: /var/lib/asterisk/agi-bin -R 

# Install PearDB
pear install DB 

# fail2ban config
sed -i 's:/var/log/asterisk/messages:/var/log/asterisk/security:' /etc/fail2ban/jail.conf

if [ ! -f /etc/fail2ban/jail.d/issabelpbx.conf ]; then

cat <<'EOF' >/etc/fail2ban/jail.d/issabelpbx.conf
[asterisk]
enabled=true

[issabelpbx-auth]
enabled=true
logpath=/var/log/asterisk/issabelpbx.log
maxretry=3
bantime=43200
ignoreip=127.0.0.1
port=80,443
EOF

cat <<'EOF' >/etc/fail2ban/filter.d/issabelpbx-auth.conf
# Fail2Ban filter for issabelpbx
#
[INCLUDES]
before = common.conf
[Definition]
failregex = ^%(__prefix_line)s\[SECURITY\].+Invalid Login.+ <HOST>\s*$
ignoreregex =
EOF
fi

# If for some reason we do not have language set, default to english
if [ "$LANGUAGE" == "" ]; then
    LANGUAGE=en_EN
fi

if [ -z "${ISSABEL_ADMIN_PASSWORD}" ]; then
   ISSABEL_ADMIN_PASSWORD=XYZADMINadmin1234
fi

# Compile issabelPBX language files
cd /usr/src/issabelPBX/
./build/compile_gettext.sh 
service apache2 start
service mariadb start

# Install IssabelPBX with install_amp
framework/install_amp --dbuser=root --installdb --scripted --language=$LANGUAGE --adminpass=$ISSABEL_ADMIN_PASSWORD

rm -f /etc/asterisk/stir_shaken.conf

# Copy fail2ban config files
/usr/bin/cp -rf $SOURCE_DIR_SCRIPT/fail2ban/action.d/*.conf /etc/fail2ban/action.d
/usr/bin/cp -rf $SOURCE_DIR_SCRIPT/fail2ban/filter.d/*.conf /etc/fail2ban/filter.d
/usr/bin/cp -rf $SOURCE_DIR_SCRIPT/fail2ban/jail.d/*.conf /etc/fail2ban/jail.d

service fail2ban start

# Logrotate
/usr/bin/cp -rf $SOURCE_DIR_SCRIPT/logrotate/asterisk_logrotate.conf /etc/logrotate.d/asterisk.conf

#Vosk docker container unit systemd
cat > /lib/systemd/system/vosk.service <<EOF
[Unit]
Description=Vosk Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=7
Restart=always
ExecStart=/usr/bin/docker run --rm --name vosk \
    -p 2700:2700 \
    issabel/vosk-asr-es:latest

ExecStop=/usr/bin/docker stop vosk

[Install]
WantedBy=multi-user.target
EOF

#Start vosk
#systemctl enable vosk.service
service vosk start

#Install asterisk vosk module
cd /usr/src
git clone  https://github.com/alphacep/vosk-asterisk
cd vosk-asterisk/
./bootstrap
./configure --with-asterisk=/usr/src/${ASTERISK_SRC_DIR} --prefix=/usr
make
make install


#Add asterisk vost module resource config file
cat > /etc/asterisk/res_speech_vosk.conf <<EOF
[general]
log-level = 0
url = ws://127.0.0.1:2700
EOF

#Load module in asterisk
/usr/sbin/asterisk -rx 'module load res_speech_vosk.so'

#Enable live dangerously
#https://docs.asterisk.org/Configuration/Dialplan/Privilege-Escalations-with-Dialplan-Functions/
sed -i 's/^;live_dangerously = no/live_dangerously = yes/g' /etc/asterisk/asterisk.conf


#Install perl lib
perl -MCPAN -e "install LWP::Protocol::https; install Digest::MD5"
