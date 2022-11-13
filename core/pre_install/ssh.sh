#!/bin/expect

exec rm -rf ~/.ssh

spawn ssh-keygen -t rsa

expect {
    ".ssh/id_rsa\)" { send "\r"; exp_continue }
    "empty for no passphrase\)" { send "\r"; exp_continue }
    "passphrase again" { send "\r"; exp_continue }
}
