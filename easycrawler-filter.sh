#!/bin/bash

#    Filter generator for crawled URLs.
#    Copyright (C) 2016 David Hedlund.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

clear
clear

if [ ! -d build ]; then echo "Run easycrawler.sh first" && exit; fi


cd build


if [ -s easylist.txt ]; then

    echo "found easylist.txt"; 

else

    wget https://easylist-downloads.adblockplus.org/easylist.txt

fi

if [ -s easyprivacy.txt ]; then

    echo "found easyprivacy.txt"; 

else

    wget https://easylist-downloads.adblockplus.org/easyprivacy.txt

fi

rm no-subdomains.txt
cp -a js_files-ref.txt easylist-new.txt

# Format
sed -i 's_^_\t\tSource: _' easylist-new.txt


##########################################
# Figure out domain names


# Remove subdomains. sudo pip install tldextract
for yp in $(cat js_files.txt); do

    if [[ $(tldextract $yp) == " "* ]]; then

	echo $yp >> no-subdomains.txt
	grep $yp easylist-new.txt >> no-subdomains.txt



    else

	foo=$(tldextract $yp | cut -d ' ' -f1);
	echo $yp | sed "s/$foo\.//" >> no-subdomains.txt

    fi;

done

sed "
s/\//\nREMOVEME/g;
s|$|\$script|g;
/ /d;
" no-subdomains.txt > domain-list.txt
sed -i '/REMOVEME/d;' domain-list.txt

sort -u domain-list.txt > tmp.txt && mv tmp.txt domain-list.txt



rm domain-list-missing.txt
for xy in $(cat domain-list.txt); do

    if cat easylist.txt | grep -q $xy; then

	echo $xy found in easylist.txt;
        
    elif cat easyprivacy.txt | grep -q $xy; then

	echo $xy found in easyprivacy.txt;
	
    else

	echo "$xy" >> domain-list-missing.txt
	grep "$xy" easylist-new.txt >> domain-list-missing.txt
    fi
    
    
done


if [ -f domain-list-missing.txt ]; then

    echo -e "
-----------------------------------------------------------------
Please return a ticket if you add something.

Domains not found in EasyList or EasyPrivacy
-----------------------------------------------------------------";
    cat domain-list-missing.txt

fi



#¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Make filters

# Remove version numbers from filters
sed -i 's/-[0-9]/-\nREMOVEME/g;' easylist-new.txt
sed -i '/REMOVEME/d;' easylist-new.txt
# Add $script (EasyList policy)
sed -i '
s/^/@@||/g;
s|$|\$script|g;
' easylist-new.txt

# Remove white list for bypass urls
sed -i '
/#bypass_url/ s/@@//g;
s/#bypass_url//g;
' easylist-new.txt

if [ -s no-subdomains.txt ];
then

    rm no-subdomains.txt

fi




# Sort list
sort -u no-subdomains.txt > tmp.txt && mv tmp.txt no-subdomains.txt

for x in $(cat no-subdomains.txt); do $(grep $x | sed 's/#bypass_url//g') easylist.txt >> no-subdomains--already-added.txt; done
echo "Unique, sorted, trimmed from version numbers, and current EasyList filters removed: "
diff -y --width=180 no-subdomains.txt no-subdomains--already-added.txt > easylist-REPORT.txt | grep "<" | sed "s/<//g; s/ //g;" | tr -d '\t'


echo -e "
Filters not found in EasyList or EasyPrivacy
-----------------------------------------------------------------"

if [ -s easylist-REPORT.txt ]; then cat easylist-REPORT.txt; fi
