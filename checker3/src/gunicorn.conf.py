import multiprocessing

worker_class = "uvicorn.workers.UvicornWorker"
workers = 1
bind = "0.0.0.0:8000"
loglevel = "debug"
timeout = 90
keepalive = 3600
preload_app = True
