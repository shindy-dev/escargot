#!/bin/bash

docker stop escargot && docker rm escargot && docker-compose up -d && docker-compose exec escargot /bin/bash