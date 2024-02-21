#!/bin/bash
mvn verify | awk '/<<< FAILURE!/{failure=1; getline; getline; getline; while (/^[[:space:]]+at/){lastline=$0; getline}} /java\.lang\.AssertionError:/{failure=0; getline; while (/^[[:space:]]+at/){lastline=$0; getline}} {if (failure && lastline) {print lastline; failure=0}}'

