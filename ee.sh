#!/bin/bash
users="$(cut -d: -f1,3 /etc/passwd)"
for user in $users; do
 username=$(cut -d: -f1 <<< $user)
 userid=$(cut -d: -f2 <<< $user)
 if [ $userid -gt 999 ]; then
 if [ ! -v allusers ]; then
 allusers="$username"
 else
 allusers+=" $username"
 fi
 fi
done
echo "Found these users: $allusers"
