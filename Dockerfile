FROM  nginx:latest

# ADD default.conf /etc/nginx/conf.d

RUN apt-get clean && apt-get update && apt-get install -y spawn-fcgi fcgiwrap  python3 python3-pip exuberant-ctags global

RUN sed -i 's/www-data/nginx/g' /etc/init.d/fcgiwrap
RUN chown nginx:nginx /etc/init.d/fcgiwrap
RUN pip3 install Pygments

ADD default.conf /etc/nginx/conf.d/

CMD /etc/init.d/fcgiwrap start \
	&& nginx -g 'daemon off;'
