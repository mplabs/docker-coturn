FROM alpine:latest
LABEL maintainer="mplabs@mplabs.de" \
      tag="coturn"

RUN apk add --no-cache --update bash coturn curl gettext jq

ADD coturn.sh /coturn.sh
RUN chmod u+x /coturn.sh

CMD /coturn.sh

