FROM alpine

LABEL maintainer="Patricio R Estevez-Soto <patricio.estevez@ucl.ac.uk>"

ARG USER=sshpinger
ENV HOME /home/$USER

RUN apk add --no-cache --virtual .build-deps build-base libssh-dev
COPY . /tmp/
RUN cd /tmp && \
    make && \
    cp bin/sshping /bin/ && \
    RUN_DEPS="$( \
        scanelf --needed --nobanner /bin/sshping \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | xargs -r apk info --installed \
            | sort -u \
    )" && \
    apk add --no-cache --virtual .run-deps $RUN_DEPS && \
    apk del --no-cache .build-deps && \
    rm -rf /tmp/*

# add new user
RUN apk add --update sudo && \
    adduser -D $USER \
        && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
        && chmod 0440 /etc/sudoers.d/$USER

USER $USER
WORKDIR $HOME

ENTRYPOINT ["sshping"]

CMD ["--help"]
