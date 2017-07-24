#!/bin/bash

#    Ad Reaper - Ad URL crawler and ad block generator.
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


#domain=tube8.com;
#retrive_main_js_files


for xyz in $(cat ../easyspider-adult-domains.txt); do
    domain=$xyz;
    retrive_main_js_files
done


sort -u js_files.txt > tmp.txt && mv tmp.txt js_files.txt
sort -u js_files-ref.txt > tmp.txt && mv tmp.txt js_files-ref.txt
cat js_files.txt



exit

#####################################################
# White list filtering

function retrive_unique_js_files {

    wget $url -O test.txt
    sed -n '/jsFileList.page_Js/,/]/p' test.txt | sed '1d;$d' > test2.txt

    cat test2.txt | tr -d '\t' > test3.txt


    sed -i '
s/?/?\\n/g;
s/,/\\n/g;
' test3.txt
    grep ".js" test3.txt > test4.txt

}


### Template ###
#url=http://www.pornhub.com/webmasters;
#retrive_unique_js_files


### Footer links ###

# Disclaimer: Anchor links call for jsFileList.page_Js too so they should not be ignored.

url=http://www.pornhub.com/information#terms;
retrive_unique_js_files

url=http://www.pornhub.com/information#privacy;
retrive_unique_js_files

url=http://www.pornhub.com/information#dmca;
retrive_unique_js_files

url=http://www.pornhub.com/information#btn-2257;
retrive_unique_js_files

url=http://www.pornhub.com/information#partner;
retrive_unique_js_files

url=http://www.pornhub.com/information#advertising;
retrive_unique_js_files

url=http://www.pornhub.com/webmasters;
retrive_unique_js_files

url=http://www.pornhub.com/amateur;
retrive_unique_js_files

url=http://www.pornhub.com/press;
retrive_unique_js_files

url=http://www.pornhub.com/information#faq;
retrive_unique_js_files

url=http://www.pornhub.com/support;
retrive_unique_js_files

url=http://www.pornhub.com/sitemap;
retrive_unique_js_files

url=http://www.pornhub.com/blog;
retrive_unique_js_files

url=http://www.pornhub.com/insights;
retrive_unique_js_files

url=http://www.pornhub.com/front/set_mobile;
retrive_unique_js_files

url=http://www.pornhub.com/front/set_mobilelite;
retrive_unique_js_files

url=http://www.pornhub.com/front/set_tablet;
retrive_unique_js_files

url=http://www.pornhub.com/more;
retrive_unique_js_files

# RTA rating
url=http://www.pornhub.com/information#rating;
retrive_unique_js_files

### VIDEOS ###

url=http://www.pornhub.com/video;
retrive_unique_js_files

# Sample
url=http://www.pornhub.com/view_video.php?viewkey=222094072;
retrive_unique_js_files

url=http://www.pornhub.com/channels;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/channels/faketaxi;
retrive_unique_js_files

url=http://www.pornhub.com/pornstars;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/pornstar/janice-griffith;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/pornstar/lisa-ann/comments;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/pornstar/lisa-ann/official_photos;
retrive_unique_js_files

url=http://www.pornhub.com/playlists;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/view_video.php?viewkey=1163369305&pkey=2623071;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/playlist/2623071;
retrive_unique_js_files

url=http://www.pornhub.com/recommended;
retrive_unique_js_files


### Categories ###

url=http://www.pornhub.com/categories;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/video?c=28;
retrive_unique_js_files


### COMMUNITY ###

url=http://www.pornhub.com/community;
retrive_unique_js_files

url=http://www.pornhub.com/user/discover;
retrive_unique_js_files

url=http://www.pornhub.com/user/search;
retrive_unique_js_files

### PHOTOS & GIFS ###

url=http://www.pornhub.com/albums;
retrive_unique_js_files
# Sample
url=http://www.pornhub.com/albums/female-straight?o=tr;
retrive_unique_js_files

url=http://www.pornhub.com/gifgenerator;
retrive_unique_js_files

url=http://www.pornhub.com/gifs;
retrive_unique_js_files


### USER PROFILE ###

url=http://www.pornhub.com/create_account_select;
retrive_unique_js_files


# Public samples

url=http://www.pornhub.com/users/therealsquirtqueen;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/playlists;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/videos;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/photos;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/gifs;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen?section=default&display=all;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/myachievements;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/pornstar_subscriptions;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/subscriptions;
retrive_unique_js_files

url=http://www.pornhub.com/users/therealsquirtqueen/channel_subscriptions;
retrive_unique_js_files


# http://www.pornhub.com/login redirects

#url=http://www.pornhub.com/feeds;
#retrive_unique_js_files

#url=http://www.pornhub.com/notifications;
#retrive_unique_js_files

#url=http://www.pornhub.com/users/<user>/videos/favorites;
#retrive_unique_js_files

#url=http://www.pornhub.com/playlist/remove_favourite;
#retrive_unique_js_files

#url=http://www.pornhub.com/video/manage;
#retrive_unique_js_files

#url=http://www.pornhub.com/user/edit;
#retrive_unique_js_files

#url=http://www.pornhub.com/user/verification;
#retrive_unique_js_files


#url=http://www.pornhub.com/user/friend_requests;
#retrive_unique_js_files

#url=http://www.pornhub.com/chat/index;
#retrive_unique_js_files

#url=http://www.pornhub.com/upload/videodata;
#retrive_unique_js_files

# Exeption
#url=http://www.pornhub.com/front/logout;
#retrive_unique_js_files

grep "@@||" full-2.txt >> compact-1.txt
sort -u compact-1.txt > compact-2.txt



#############################################
# Blacklist filtering

# Retrive connected hosts to build new blacklist filters.
#wget -E -H -p http://pornhub.com/


# Keep JavaScript only
#wget mobile.pornhub.com/; sed -n "/<script/,/<\/script>/p" index.txt > index.js

echo "Run ./easycrawler-filters.sh now"
