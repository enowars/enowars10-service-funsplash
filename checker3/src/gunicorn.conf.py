worker_class = "uvicorn.workers.UvicornWorker"
workers = 4
bind = "0.0.0.0:8000"
loglevel = "debug"
timeout = 90
keepalive = 3600
preload_app = True
