This is a simple bash script to automate renaming and copying files to your AppleTV, (or any media server with ssh).

How to use
==========

Open ~/.profile in your preferred editor and type the following

    . path/to/atv_boxee.sh
    bxvolume=MyVolume

Then, to simply ssh to your server, just type:

    bx

You can transfer files to the server using

    bx <filename>

This will try to find the show name, season, episode and title of the file and copy it to:

    frontrow@appletv.local:/Volumes/MyVolume/TV/{show}/Season {season}/{show} - {season}x{episode} - {title}.ext

for example:

    frontrow@appletv.local:/Volumes/MyVolume/TV/PurePwnage/Season 01/PurePwnage - 01x10 - Teh Best Day Ever.avi

The original file will remain unchanged.

This format is ideal for [Boxee](http://boxee.tv/ "Boxee") to recognise and index the file. This location can be changed by overriding any of the variables defined at the top of the script. For instance you could put the following in your .profile:

    . path/to/atv_boxee.sh
    bxvolume=MyVolume
    bxserver=user@mysshserver.local
    bxshowfile="\${show} s\${season}e\${episode} \${title}"
    bxtvdir="My Shows"

The above example would now be copied to:

    user@mysshserver.local:/Volumes/MyVolume/My Shows/PurePwnage/Season 01/PurePwnage s01e10 Teh Best Day Ever.avi

You can use any bash expression here. For example, you could use "\${season#0}" to remove the leading 0 from the season parameter. See the [bash reference manual](http://www.gnu.org/software/bash/manual/bashref.html#Shell-Parameter-Expansion "Bash reference"] for details.

Enjoy.