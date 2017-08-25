#!/bin/bash

#    EasyCrawler - Web crawler for EasyList and EasyPrivacy.
#    "I sincerely hope this project can be merged to https://github.com/easylist/easycrawler"
#    Copyright (C) 2016, 2017 David Hedlund.
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

DIR="`dirname \"$0\"`"
filename=$(basename "$0")

case "$1" in
    
    ""|-help)
	
	echo "Usage: $filename [--option]

OPTIONS
    --check-domains       View all domains that will be operated on.
    --all                 Run all operational options.
      --retrive           Get a lists of .js files (time consuming).
      --analyse-easylist  Figure out .js files not in EasyList/EasyPrivacy.
" && exit 1

        ;;

    --all)

        $0 --retrive
        $0 --analyse-easylist

        ;;

    --check-domains)

        for i in $(find $DIR -maxdepth 1 -name "easycrawler-domains*.txt"); do

            echo "--------------------------------------------------
$i:"

            cat $i
            
        done

        ;;

    --retrive)

        #######################################
        # Dependencies

        # js_beautify is provided by libjavascript-beautifier-perl

        unmet_dependencies () {
            
            if [ "$(dpkg-query -W -f='${Status}' $package 2>/dev/null | grep -c "ok installed")" -eq 0 ];
            then
                "$packaged not installed." && exit
            fi

        }

        package="curl"; unmet_dependencies
        package="libjavascript-beautifier-perl"; unmet_dependencies
        package="wget"; unmet_dependencies

        if [ ! -f /usr/local/bin/tldextract ]; then echo "tldextract not installed (normally installed with: sudo pip install tldextract)"; fi

        #######################################


        loop=1;


        if [ -d "build" ]; then
            
            rm -fr build # Start with a fresh build
            
        fi

        mkdir build
        cd build



        #######################################



        # For security, set fetch to otherwise reuse the downloaded files
        # to possilby being network monitored by the download server.

        if [[ "$1" = "fetch" ]];
        then

            fetch=true;

        fi




        #####################################
        # Get bulk JS files



        function retrive_main_js_files {
            
            mkdir -p $domain
            cd $domain
            wget $domain

            # ¤¤¤ 1: Copy JS related content ¤¤¤
            sed -n "/<script/,/<\/script>/p" index.html > index-script.html


            # ¤¤¤ 2: Get files from "<script src=" ¤¤¤
            grep "<script src=\"" index-script.html > js_files1.html
            grep "<script type=\"text/javascript\" src=\"" index-script.html >> js_files1.html
            cat js_files1.html | tr -d '\t' > js_files2.html

            # A script line can look like this<script src="http://ss.phncdn.com/tubes-1.0.0.js" async defer></script
            sed -i "
s|\"|\n\"\n|g;
s|'|\n'\n|g;
" js_files2.html

            grep "\.js" js_files2.html > js_files-$loop.txt
            grep "\.php" js_files2.html >> js_files-$loop.txt

            # ¤¤¤ 3: Get inline JS files ¤¤¤

            sed '/<script /d; /<\/script>/d;' index-script.html > obfuscated-$loop.js # Remove HTML else js_beautify cannot be used


            function beautify {
                
                # Breaking compression bypass detection
                if [[ $(file -bi obfuscated-$loop.js) == "application/gzip; charset=binary" ]]; then
	            
	            mkdir extract
	            cd extract
	            cp -a ../obfuscated-$loop.js obfuscated-$loop.gz
	            gunzip obfuscated-$loop.gz
	            mv obfuscated-$loop ../obfuscated-$loop.js # Leave a copy
	            cd ..
	            
                fi
                
                # js_beautify must be done before anytning else
                js_beautify obfuscated-$loop.js > beautify-$loop.js # part of package libjavascript-beautifier-perl
                # Repair bugs caused by js_beautify
                sed -i "s/http: /http:/g" beautify-$loop.js
                # Get files
                grep "\.js" beautify-$loop.js > js_files-$loop.js
                grep "\.php" beautify-$loop.js >> js_files-$loop.js
                


                # Translate bypass characters used from https://tools.ietf.org/html/rfc4516
                sed -i "
s|x2F|/|g;
s|x3A|:|g;
" js_files-$loop.js
                
                # Get absolute URLs
                sed -i "
s|\"|\n\"\n|g;
s|'|\n'\n|g;
" js_files-$loop.js
                

                grep "\.js" js_files-$loop.js > js_files2-$loop.js
                grep "\.php" js_files-$loop.js >> js_files2-$loop.js


                # Break down bypass URLs but keep track of them for later
                sed -i '/\\/ s/$/#bypass_url/g' js_files2-$loop.js
                sed -i 's|\\||g;' js_files2-$loop.js

                sed -i '
# Remove directory URL
/\/$/d;
/ /d;
' js_files2-$loop.js


                cat js_files2-$loop.js >> js_files-$loop.txt


                ### Make filters of collected JS files ###

                # Remove undeclared protocols
                sed -i "
s|^//||g;
s|^://||g;
s|^\.||g;
" js_files-$loop.txt

                # Keep valid lines
                grep "/" js_files-$loop.txt | grep "\.js" > tmp.txt
                grep "/" js_files-$loop.txt | grep "\.php" >> tmp.txt
                mv tmp.txt js_files-$loop.txt


                if [ -s js_files-$loop.txt ]; then

                    # Make begining of filter proper
                    sed -i "
s|^/|$domain/|g;
s|Source:|$domain/|g;
s|www\.||g;
s|http://||g;
s|https://||g;
" js_files-$loop.txt
                    # /\/\//d;


	            # Sort list
	            sort -u js_files-$loop.txt > tmp.txt && mv tmp.txt js_files-complete-$loop.txt


                    # Keep ? (EasyList policy) but not anything after it
	            sed -i "
s|?|?\nREMOVEME|g;
" js_files-complete-$loop.txt

	            sed -i "
/REMOVEME/d;
" js_files-complete-$loop.txt

                    # This must be set last to break down bypass URLs to not include regular text too.
                    sed -e "s| ||g;" js_files-complete-$loop.txt


                    # Keep only valid urls
                    if [ -s tmp ]; then rm tmp; fi

                    for p in $(cat js_files-complete-$loop.txt); do


                        # Test URL - This will exclude directories
                        if curl -sSf $p > /dev/null; then echo $p >> tmp.txt; fi

                    done

                    mv tmp.txt js_files-complete-$loop.txt
                    cp -a js_files-complete-$loop.txt js_files-ref-$loop.txt


                    # Add reference

                    if [ -s tmp ]; then
                        
                        foox=$(cat tmp)" > ";
                        
                    fi

                    sed -i "s|^|$domain > $foox|g;" js_files-ref-$loop.txt




                fi







            }
            beautify

            #¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
            # Investigate js_files-$loop for more js_files-$loop

            for js_file in $(cat js_files-complete-$loop.txt); do


                loop=$((loop+1))
                echo "$domain $loop";
                wget $js_file -O obfuscated-$loop.js
                echo "$js_file" > tmp
                beautify


            done

            cat js_files-complete-* >> $domain.js_files.txt
            sort -u $domain.js_files.txt > tmp.txt && mv tmp.txt $domain.js_files.txt

            cat js_files-ref-* >> $domain.js_files-ref.txt
            sort -u $domain.js_files-ref.txt > tmp.txt && mv tmp.txt $domain.js_files-ref.txt


            # Delete empty files
            find . -size 0 -delete

            cat $domain.js_files.txt >> ../js_files.txt
            cat $domain.js_files-ref.txt >> ../js_files-ref.txt

            # Prepare for next
            loop=1;
            cd ..
            rm tmp

        }

        for i in $(find ../ -maxdepth 1 -name "easycrawler-domains*.txt"); do

            echo "--------------------------------------------------
$i:"

            for xyz in $(cat $i); do
                domain=$xyz;
                echo "$domain"
                retrive_main_js_files
            done
            
        done


        sort -u js_files.txt > tmp.txt && mv tmp.txt js_files.txt
        sort -u js_files-ref.txt > tmp.txt && mv tmp.txt js_files-ref.txt
        cat js_files.txt

        ;;

    --analyse-easylist)
        
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

        ;;

esac

exit 0
