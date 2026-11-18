#!/bin/sh
set -eu

apt-get install -y -qq ruby-bundler sudo >/dev/null
id tester >/dev/null 2>&1 || useradd -m tester
printf 'tester ALL=(ALL) NOPASSWD:ALL\n' >/etc/sudoers.d/tester
rm -rf /home/tester/repo
mkdir -p /home/tester/repo
(cd /repo && tar -cf - .) | (cd /home/tester/repo && tar -xf -)
rm -rf /home/tester/repo/vendor /home/tester/repo/.bundle /home/tester/repo/coverage
chown -R tester:tester /home/tester/repo
status=0
su tester -c 'cd ~/repo && bundle config set --local path vendor/bundle >/dev/null && bundle install --quiet && sh .github/scripts/coverage.sh' || status=$?
cp -f /home/tester/repo/coverage/.resultset.json /repo/coverage-linux.json
cp -f /home/tester/repo/coverage/bashcov-warnings.log /repo/coverage-linux-warnings.log
exit "${status}"
