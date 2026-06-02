FROM python:3.14-alpine
RUN apk add --no-cache libzbar binutils
RUN ln -s /usr/lib/libzbar.so.0 /usr/lib/libzbar.so

# add checker user
RUN adduser -s /bin/bash -u 1000 checker -D -S

WORKDIR /checker

COPY requirements.txt .

USER checker
RUN python3 -m pip install -r requirements.txt

COPY ./src .

ENTRYPOINT [ "/home/checker/.local/bin/gunicorn", "-c", "gunicorn.conf.py", "checker:app" ]
