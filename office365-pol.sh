#!/usr/bin/env playonlinux-bash

# Microsoft 365 Apps / Office 365 install script for PlayOnLinux
# Version 1.0, developed by DonutsB, released in June 2021
# Tested with PlayOnLinux 4.3.4 on Manjaro Linux version 21.0.7
# The newest version of the script, documentation for it and an issue tracker are availabe at $BLUBBERDUBBER
# This software is released under the Zero-Clause BSD licence:
#
# Start of license agreement
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# End of license agreement

[ "$PLAYONLINUX" = "" ] && exit 0
source "$PLAYONLINUX/lib/sources"

TITLE="Microsoft 365 Apps / Office 365"
SHORTNAME="Office365"
WINEVERSION="cx-20.0.4"
SYSARCH="x86"

# Initial greetings
POL_SetupWindow_Init
POL_Debug_Init
POL_SetupWindow_presentation "$TITLE" "Microsoft" "https://www.office.com" "DonutsB" "$SHORTNAME"
wbinfo -V || WINBINDMISSING="yes"
if [ "$WINBINDMISSING" = "yes" ]
then
    POL_SetupWindow_message "$(eval_gettext "Winbind needs to be installed for the Office installer to work. Since winbind doesn't appear to be installed on your system, the PlayOnLinux Wizard will now quit. Please install winbind and then try again. If you can't find it in your distro's package management system, try installing samba, which sometimes contains winbind.")" "$(eval_gettext "Error")"
    POL_SetupWindow_Close
    exit
fi
POL_SetupWindow_message "$(eval_gettext "This script requires Codeweavers' Wine variant in version 20.0.4, for which you can only get the source code, but no binaries. So, you'll have to compile it yourself. Instructions for this are available at $BLUBBERDUBBER, but it generally isn't recommended for beginners. This script also assumes that you have all fonts that normally ship with Windows 7 or higher installed.")" "$(eval_gettext "Warning")"

# Let the user select OfficeSetup.exe
POL_SetupWindow_browse "$(eval_gettext "Please select the downloaded installer. You have to use the online (!) installer for the 32-bit (!) version of Microsoft 365 Apps / Office 365.")" "$TITLE"

# Create the Wine prefix
POL_Wine_SelectPrefix "$SHORTNAME"
POL_System_SetArch "$SYSARCH"
POL_Wine_PrefixCreate "$WINEVERSION"
Set_OS "win8"

# Apply registry modifications
POL_System_TmpCreate "$SHORTNAME"
echo 'W i n d o w s   R e g i s t r y   E d i t o r   V e r s i o n   5 . 0 0 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ M i c r o s o f t \ O f f i c e \ C l i c k T o R u n \ C o n f i g u r a t i o n ] 
 " C D N B a s e U r l " = " h t t p : / / o f f i c e c d n . m i c r o s o f t . c o m / p r / 7 f f b c 6 b f - b c 3 2 - 4 f 9 2 - 8 9 8 2 - f 9 d d 1 7 f d 3 1 1 4 " 
  [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ D l l O v e r r i d e s ] 
 " r i c h e d 2 0 " = " n a t i v e , b u i l t i n " 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ E n a b l e U I A u t o m a t i o n C o r e ] 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ M a c   D r i v e r ] 
 " O p e n G L S u r f a c e M o d e " = " b e h i n d " 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ M S H T M L \ M a i n T h r e a d H a c k ] 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ E n a b l e O L E Q u i t F i x ] 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ D i r e c t 2 D ] 
 " m a x _ v e r s i o n _ f a c t o r y " = d w o r d : 0 0 0 0 0 0 0 0 
 [ H K E Y _ C U R R E N T _ U S E R \ S o f t w a r e \ W i n e \ X 1 1   D r i v e r ] 
 " S c r e e n D e p t h " = " 3 2 "   ' > "$POL_System_TmpDir/pre-install.reg"
POL_Wine "regedit.exe" "/c" "$POL_System_TmpDir/pre-install.reg"
POL_System_TmpDelete

# Let the user select Windows 7
POL_SetupWindow_message "$(eval_gettext 'To work around a problem with Wine, you have to manually select Windows 7 as the emulated Windows version. After clicking "Next", change Windows 8 to Windows 7 in the configuration menu that pops up, then click "OK".')" "$SHORTNAME"
POL_SetupWindow_wait "$(eval_gettext 'Please select Windows 7 and then click "OK".')" "$SHORTNAME"
POL_Wine "winecfg.exe"

# Install prerequisites
POL_Call POL_Install_msxml6
POL_Call POL_Install_vcrun2019

# Install Office
POL_SetupWindow_wait "$(eval_gettext "Office Setup is running")" "$SHORTNAME"
POL_Wine "$APP_ANSWER"

# Quit the Office setup that doesn't want to close by itself
pkill OfficeC2RClient

POL_SetupWindow_wait "$(eval_gettext "Finishing up...")" "$SHORTNAME"

# Copy missing DLL files
cp "$WINEPREFIX/drive_c/Program Files/Common Files/Microsoft Shared/ClickToRun/AppvIsvSubsystems32.dll" "$WINEPREFIX/drive_c/Program Files/Microsoft Office/root/Office16/"
cp "$WINEPREFIX/drive_c/Program Files/Common Files/Microsoft Shared/ClickToRun/C2R32.dll" "$WINEPREFIX/drive_c/Program Files/Microsoft Office/root/Office16/"

# Create shortcuts
POL_Shortcut "WINWORD.EXE" "Microsoft Word (MS365)" "" "" "Office;WordProcessor;TextEditor;"
POL_Shortcut "EXCEL.EXE" "Microsoft Excel (MS365)" "" "" "Office;Spreadsheet;Chart;"
POL_Shortcut "POWERPNT.EXE" "Microsoft PowerPoint (MS365)" "" "" "Office;Presentation;"
POL_Shortcut "ONENOTE.EXE" "Microsoft OneNote (MS365)" "" "" "Office;"
POL_Shortcut "OUTLOOK.EXE" "Microsoft Outlook (MS365)" "" "" "Network;Email;Calendar;ContactManagement;"
POL_Shortcut "MSACCESS.EXE" "Microsoft Access (MS365)" "" "" "Ofice;Database;Building;"
POL_Shortcut "MSPUB.EXE" "Microsoft Publisher (MS365)" "" "" "Office;Publishing;WordProcessor;"

# Done!
POL_SetupWindow_message "$(eval_gettext "Microsoft Office should now be installed. If you run into significant issues that don't occur under Windows, please report them at $BLUBBERDUBBER. Or, if they're already reported, you may find a workaround there.")" "$(eval_gettext "Done!")"

POL_SetupWindow_Close
exit
