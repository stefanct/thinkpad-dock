Example ThinkPad docking script for multi-monitor
-------------------------------------------------

You will probably need to modify these files to suit your multi-monitor layout, your username and your dock model.  Tested on Fedora 20 with a series 3 ThinkPad Dock.

Warning: this can and will mess up your display if anything goes wrong.


1. First, unless you have a `ThinkPad Mini Dock Plus Series 3`, you need to find the udev identity of your dock, so that we can detect when it is added or removed.

Run this command: 

    udevadm monitor --environment --udev

Then disconnect the hub, wait a second for the events to be logged, press enter several times (on the laptop keyboard) to put a gap after the events, then reconnect the hub.

Make a note of the last usb device to be removed in the log (just before the gap), for instance:


    UDEV  [62731.120389] remove   /devices/pci0000:00/0000:00:1d.0/usb2/2-1/2-1.8 (usb)
    ACTION=remove
    ...
    ID_MODEL=100a
    ...
    ID_MODEL_FROM_DATABASE=ThinkPad Mini Dock Plus Series 3
    ...
    ID_VENDOR=17ef




The same device should be among the first to be added again:

    UDEV  [62736.651278] add      /devices/pci0000:00/0000:00:1d.0/usb2/2-1/2-1.8 (usb)
    ACTION=add
    ...
    ID_MODEL=100a
    ...
    ID_MODEL_FROM_DATABASE=ThinkPad Mini Dock Plus Series 3
    ...
    ID_VENDOR=17ef


Hit Control-C to stop monitoring.

Make sure the values `ID_MODEL` and `ID_VENDOR` are shown both for `add` and `remove`.  We will use these to construct a udev rule.  If you try to use a value which isn't there when removing, your rule won't activate for `remove` events.

If `ID_MODEL` and `ID_VENDOR` don't look like hex numbers, you might want to try `ID_MODEL_ID` and `ID_VENDOR_ID`.


2. If you have a `ThinkPad Mini Dock Plus Series 3`, your values should match the ones above, and you can use this rule as is, otherwise you should adjust `ID_MODEL` and `ID_VENDOR` to match your results (or perhaps use `ID_MODEL_ID` and `ID_VENDOR_ID`):

Save the file `81-thinkpad-dock.rules` (modified if necessary) as `/etc/udev/rules.d/81-thinkpad-dock.rules`.

3. Modify the username and the `xrandr` commands in `thinkpad-dock.sh` as appropriate, and save as `/etc/sbin/thinkpad-dock.sh`.  Make sure it is executable: `chmod 755 /etc/sbin/thinkpad-dock.sh`

4. Try docking and undocking your laptop.  If nothing happens, you might have a problem with Xauthority (check the username), or you might be using the wrong rules file for your hardware IDs.  If something happens, but you don't get the screen layout you want, check the documentation for `xrandr` with `man xrandr`.

You can test the script without physically undocking by running these commands as root:

Docking:

    ACTION=add sbin/thinkpad-dock.sh

Undocking:

    ACTION=remove sbin/thinkpad-dock.sh


A couple of extra notes:

`journalctl -f | grep DOCKING` will let you see the script's logging messages as they happen.


If you make a note of the device name returned by `udevadm monitor` when docking/undocking, you can see what will happen when the udev event is triggered by running commands similar to these:

    udevadm test --action=add /devices/pci0000:00/0000:00:1d.0/usb2/2-1/2-1.8
    udevadm test --action=remove /devices/pci0000:00/0000:00:1d.0/usb2/2-1/2-1.8
