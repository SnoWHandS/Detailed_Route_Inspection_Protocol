#!/bin/bash

cd simple_router/ipv4_router

make run

echo "

Running make stop to close mininet background session.

"
make stop
