#!/bin/sh
set -e

#PKG=$(pkg_info | grep -E '^(apache-ant|jdk|openal|maven|rsync|lwjgl|xz)\-' | wc -l)
#if [ "$PKG" -eq 7 ]
#then
#	echo "Packages installed: OK"
#else
#	echo "Packages missing. Required packages are apache-ant, jdk, openal, maven, rsync, lwjgl, xz"
#	exit 1
#fi

if [ ! -f desktop-*.jar ]
then
	echo "You need to have a desktop-*.jar file in the current folder. You can find it in the files of the game installed via Steam (windows or linux)."
	exit 2
fi

export JAVA_HOME=/usr/local/jdk-11
export PATH=$PATH:$JAVA_HOME/bin

# extract
mkdir unjar
cd unjar
GAME_FOLDER=$PWD
/usr/local/jdk-11/bin/jar xvf ../desktop-*.jar

# remove java files
rm -fr com/badlogic

# copy libs
cp /usr/local/share/lwjgl/liblwjgl64.so liblwjgl64.so
cp /usr/local/lib/libopenal.so.* libopenal64.so 

# download and extract libgdx-openbsd
ftp https://perso.pw/gaming/libgdx199-openbsd-0.0.tar.xz
unxz < libgdx199-openbsd-0.0.tar.xz | tar xvf -

# build some so files
cd $GAME_FOLDER/libgdx-openbsd/gdx/jni && ant -f build-openbsd64.xml
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-freetype/jni && ant -f build-openbsd64.xml 

# copy so files
cd $GAME_FOLDER
find libgdx-openbsd -type f -name '*.so' -exec cp {} . \;

cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-jnigen && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/gdx/ && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/backends/gdx-backend-lwjgl/ && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-freetype && mvn package && \
	rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-controllers/gdx-controllers && \
	mvn package && rsync -avh target/classes/com/ $GAME_FOLDER/com/
cd $GAME_FOLDER/libgdx-openbsd/extensions/gdx-controllers/gdx-controllers-desktop && \
	mvn package && rsync -avh target/classes/com/ $GAME_FOLDER/com/

echo "You can run the game with the following command in the 'unjar' directory:"
echo "java -Xmx1G -Dsun.java2d.dpiaware=true com.megacrit.cardcrawl.desktop.DesktopLauncher"
