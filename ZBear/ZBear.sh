#!/bin/bash

#####################################################################################
    #Software Purpose
#####################################################################################
	zenity --info --title=ZBear --width=400 --height=200 --icon-name=system-software-install --window-icon=PetitOursLogoMini.png --text \
	"<span font-family='Arial'><big>Le logiciel <span color='#E0BE04' font-weight='bold'>ZBear</span> à pour but de vous permettre de joindre le domaine <span color='#CC0000'>Active Directory</span> de votre choix sans taper une ligne de commande sur toutes les distrutions Linux basé sous RHEL et Debian.</big></span>"
	
#####################################################################################
    #Add or delete an AD domain
#####################################################################################

	launchChoice=$(zenity --list --title=ZBear --width=350 --height=200 --window-icon=PetitOursLogoMini.png --text="Voulez vous ajouter ou supprimer un domaine AD ?" \
	--column=Cocher --column=Choix Vrai Ajouter Faux Supprimer --radiolist);
    
    if [ "$launchChoice" == "Supprimer" ]; then
        domainToDelete=`zenity --entry --text "Veuillez entrer le nom du domaine en entier"`
        deleteDomain=$(realm leave "${domainToDelete^^}" > /dev/null 2>&1)
        zenity --info --title=ZBear --width=400 --height=200 --icon-name=system-software-install --window-icon=PetitOursLogoMini.png --text \
        "Le domaine à correctement été supprimer"
        exit
    else
        deleteDomain=""
    fi

#####################################################################################
    #Download or not all the necessary packages to join the AD domain
#####################################################################################

	downloadChoice=$(zenity --list --title=ZBear --width=350 --height=200 --window-icon=PetitOursLogoMini.png --text="Voulez vous installer les paquets reamld et ses dépendances ?" \
	--column=Cocher --column=Choix Vrai Oui Faux Non --radiolist);

	if [ "$downloadChoice" == "Oui" ]; then
		distroChoice=$(zenity --list --window-icon=PetitOursLogoMini.png --title=ZBear --text="Choisissez la base de votre distro Linux" --width=350 --height=200 --column=Choix --column=Base Vrai RHEL Faux  Debian --radiolist);


        if [ "$distroChoice" == "RHEL" ]
        then
            #RHEL
            (
                echo "16"
                dnf -y install realmd
                echo "32"
                dnf -y install sssd
                echo "48"
                dnf -y install oddjob
                echo "64"
                dnf -y install oddjob-mkhomedir
                echo "80"
                dnf -y install adcli samba-common-tools
                echo "100"
                echo "# Installation terminé"
            )|
                    zenity --progress \
            --title="ZBear" \
            --text="Installation des paquets nécessaires...\nCela peut prendre plusieurs minutes...\nCliquez sur OK à la fin du chargement\n" \
            --percentage=0 \
            --width=450 --height=150

            if [ "$?" = -1 ] ; then
                    zenity --error --width=450 --height=150 --window-icon=PetitOursLogoMini.png --title=ZBear --text "Une erreur c'est produite"
            fi;
        elif [ "$distroChoice" == "Debian"  ]
        then
            #Debian
                    (
                            echo "14"
                            dnf -y install realmd
                            echo "28"
                            dnf -y install sssd
                            echo "42"
                            dnf -y install sssd-tools
                            echo "56"
                            dnf -y install adcli krb5-user
                            echo "70"
                            dnf -y install packagekit samba-common
                            echo "84"
                            dnf -y install samba-common-bin samba-libs
                            echo "100"
                            echo "# Installation terminé"
                    )|
                    zenity --progress \
                    --title="ZBear" \
                    --text="Installation des paquets nécessaires...\nCela peut prendre plusieurs minutes...\nCliquez sur OK a la fin du chargement\n"
                    --percentage=0 \
                    --width=450 --height=150

                    if [ "$?" = -1 ] ; then
                            zenity --error --width=450 --height=150 --window-icon=PetitOursLogoMini --title=ZBear --text "Une erreur c'est produite"
                    fi;
        else
            exit;
        fi;
        
    elif [ "$downloadChoice" == "Non" ]; then
        downloadChoice="";
    else
        exit;
	fi

#####################################################################################
    #Modify system settings to add dns server address
#####################################################################################

	zenity --info --title=ZBear --width=400 --height=200 --window-icon=PetitOursLogoMini.png --text \
	"<span font-family='Arial'><big>Avant de continuer, vérifier que le <span font-weight='bold' color='#CC0000'>DNS</span> à correctement était renseigner dans les paramètres de votre système. Si vous n'avez pas eu le temps de redémarrer votre système après avoir modifié votre configuration système, veuillez renseigner l'adresse <span font-weight='bold' color='#CC0000'>DNS</span> du serveur dans la fenêtre suivante qui modifiera pour vous le fichier <span font-weight='bold' color='#CC0000'>resolv.conf</span> .</big></span>\n \n<span><small><u>Aide :</u>\nParamètre > Connexion > IPV4 > Sélectionnez 'Automatique (Seulement l'adresse)' > puis remplissez l'adresse DNS dans le champ adéquate</small></span>"

#####################################################################################
    #Fulfill the form with AD server information
#####################################################################################

    cfgpass=`zenity --forms \
    --title="ZBear" \
    --window-icon=PetitOursLogoMini.png \
    --text="     Remplissez les informations pour la jointure     \n     Pensez à renseigner le DNS dans la configuration de votre système au préalable     \n\n" \
    --add-entry="Nom d'hote pour changement (optionnel)" \
    --add-entry="Adresse DNS du serveur (optionnel)" \
    --add-entry="Nom entier du domaine" \
    --add-entry="Utilisateur administrateur du domaine" \
    --add-password="Mot de passe de l'administraeur du domaine" \
    --separator="|"`
 
	if [ "$?" -eq 1 ]; then
        exit
	fi

#####################################################################################
    #Get information from the form
#####################################################################################

	resultHost=$(echo "$cfgpass" | cut -d "|" -f1)
	if [ "$resultHost" != "" ]; then hostnamectl set-hostname "$resultHost"; fi
	resultDNS=$(echo "$cfgpass" | cut -d "|" -f2)
	if [ "$resultDNS" != "" ]; then resolvDNS=$(echo "nameserver $resultDNS" > /etc/resolv.conf); fi
	resultDomain=$(echo "$cfgpass" | cut -d "|" -f3)
	resultDomainUpper=${resultDomain^^}
	resultUser=$(echo "$cfgpass" | cut -d "|" -f4)
	resultMdp=$(echo "$cfgpass" | cut -d "|" -f5) # Add <| md5sum> at the end of the line to encrypt the string
	realm discover $resultDomain 2> /tmp/discoverErr.txt
	discoverErr=$(</tmp/discoverErr.txt)
	conditionTester="realm: No such realm found: $resultDomain"

#####################################################################################
    #Continue to join command if 'realm discover' worked
#####################################################################################

	if [ "$discoverErr" == "$conditionTester" ]
	then
		zenity --error --width=450 --height=150 --window-icon=PetitOursLogoMini.png --title=ZBear --text "Nous n'avons pas pu communiquer avec votre serveur Active Directory"
		exit;
	else
		(
                echo "15"
                echo "$resultMdp" | realm join -U "$resultUser"@"$resultDomainUpper" "$resultDomainUpper" 2> /tmp/joinErr.txt
                joinErr=$(</tmp/joinErr.txt)
                if [ "$joinErr" == "realm: No such realm found" ]; then joinErr=" Une erreur est survenue"; else joinErr=" Tout a fonctionné"; fi
                echo "100"
                echo "# Opération terminé : $joinErr"
        )|
        zenity --progress \
        --title="ZBear" \
        --text="Connexion en cour...\nCliquez sur OK à la fin du chargement\n" \
        --percentage=0 \
        --width=450 --height=150

        if [ "$?" = -1 ] ; then
            zenity --error \
            --title=ZBear --window-icon=PetitOursLogoMini.png --text="Une erreur c'est produite."
            exit;
        fi
        
        joinErrCheck=$(</tmp/joinErr.txt)
        if [ "$joinErrCheck" == "realm: No such realm found" ]; then 
            joinErrCheck=" Une erreur est survenue avec le realm list";
            exit;
        else 
            joinErrCheck=" Tous à fonctionner"; 
            listResult=$(realm permit --all)
            zenity --info --title=ZBear --width=400 --height=200 --icon-name=system-software-install --window-icon=PetitOursLogoMini.png --text \
            "<span font-family='Arial'><big>Votre ordinateur à correctement rejoint le domaine, tous les utilisateurs du domaine sont capable de se connecter à votre ordinateur, pensé à utiliser la synthax suivante pour l'identifiant de connexion : <span font-weight='bold'>Utilisateur@NOMDEDOMAINE</span> .</big></span>"
        fi
        
	fi
#####################################################################################
    #End
#####################################################################################
