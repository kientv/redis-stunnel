FROM ubuntu
MAINTAINER kientv <kientranvan@gmail.com>

EXPOSE 6380

RUN apt-get update && apt-get install -y stunnel4

VOLUME /stunnel
ADD ./stunnel.conf /stunnel/

CMD [ "./stunnel4", "/stunnel/stunnel.conf" ]
