#!/bin/bash -xe

rm -rf build/tools

# setup env
virtualenv --clear build
source build/bin/activate

# install depends
pip install --upgrade colorlog pyyaml psutil!=4.4.0 lxml cssselect nose nose-exclude urwid six selenium progressbar33 locustio pyvirtualdisplay pynsist astunparse https://github.com/Blazemeter/apiritif/archive/master.zip ipaddress

# run unit tests if not in Jenkins
    ./run-test.sh

# build source distribution
./build-sdist.sh

# build a windows installer
./build-windows-installer.sh ./dist/bzt-*.tar.gz

# re-setup env
deactivate
virtualenv --clear --system-site-packages build
source build/bin/activate

# run installation test
cd build # cd is to make it not find bzt package from sources
pip install --upgrade ../dist/bzt-*.tar.gz
pip install locustio
cd ..

# prepare and run functional tests
rm -rf ~/.bzt
if [ -f /etc/bzt.d/50-pbench-enhanced.json ]; then
    mkdir -p build/etc/bzt.d/
    ln -sf /etc/bzt.d/50-pbench-enhanced.json build/etc/bzt.d/
fi
echo '{"settings": {"artifacts-dir":"build/test/%Y-%m-%d_%H-%M-%S.%f"}}' > build/etc/bzt.d/99-artifacts-dir.json
echo '{"install-id": "UnitTest"}' > build/etc/bzt.d/99-zinstallID.json
mkdir -p ~/.bzt/selenium-taurus/mocha
npm install selenium-webdriver@2.53.3 --prefix ~/.bzt/selenium-taurus/mocha

export DBUS_SESSION_BUS_ADDRESS=/dev/null  # https://github.com/SeleniumHQ/docker-selenium/issues/87
bzt -install-tools -v
bzt examples/all-executors.yml -o modules.console.disable=true -sequential -o modules.rspec.interpreter=ruby2.0 -o 'modules.selenium.chromedriver.version="2.27"'
