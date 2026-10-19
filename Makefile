COMPOSE = docker compose -f srcs/docker-compose.yml
DATA = /home/aosset-o/data

all: up

up:
	mkdir -p $(DATA)/wordpress $(DATA)/mariadb
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

logs:
	$(COMPOSE) logs -f

fclean:
	$(COMPOSE) down -v --rmi all
	sudo rm -rf $(DATA)

re: fclean all

.PHONY: all up down stop start logs fclean re