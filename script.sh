#!/bin/bash
refresh=true

connected_device_list=$(bluetoothctl devices Connected | sed 's/Device //g' | sed 's/./ 󰂱  /18')
connected_device_mac=$(echo $connected_device_list | sed 's/ .*//g' )
paired_device_list=$(bluetoothctl devices Paired | sed 's/Device //g' | sed 's/./   /18')
paired_device_mac=$(echo $paired_device_list |  sed 's/ .*//g' )

while ($refresh == true) 
do

  device_list=$(bluetoothctl devices | sed '/..-..-..-..-..-../d' | sed 's/^.*Device //g' )

  for i in $paired_device_mac
  do 
    device_list=$(echo "$device_list" | sed -e "/$i/d") 
  done
  
  for i in $connected_device_mac
  do 
    paired_device_list=$(echo "$paired_device_list" | sed -e "/$i/d") 
  done
  
  if [[ -z $connected_device_list ]]; then
    final_device_list="$paired_device_list\n$device_list"
  elif [[ -z paired_device_list ]]; then 
    final_device_list="$device_list"
  else
    final_device_list="$connected_device_list\n$paired_device_list\n$device_list"
  fi


  connected=$(bluetoothctl show | grep 'PowerState')
  if [[ "$connected" =~ "PowerState: on" ]]; then
    refresh_message="󰂲 Disable Bluetooth\n Refresh\n$final_device_list"
  elif [[ "$connected" =~ "PowerState: off" ]]; then
    refresh_message="󰂯 Enable Bluetooth"
  fi 

  device_selected=$(echo -e "$refresh_message" | sed 's/^..:..:..:..:..:.. //g' | rofi -replace -dmenu -i -p "Select a device") 

  if [[ "$device_selected" =~ " Refresh" ]]; then
    refresh=true
    bluetoothctl -t 3 scan on
    notify-send "Refreshing..."
  elif [[ "$device_selected" =~ "󰂯 Enable Bluetooth" ]]; then
    bluetoothctl power on 
    nofity-send "Bluetooth powered on"
    refresh=true
  else
    refresh=false
  fi

done

if [[ "$device_selected" =~ "󰂲 Disable Bluetooth" ]]; then
  bluetoothctl power off
  nofity-send "Bluetooth powered off"
elif [[ -n $device_selected ]]; then
  echo $final_device_list
  echo "$device_selected"
  device_mac=$(echo -e "$final_device_list" | grep "$device_selected" | sed 's/ .*//g')
  device_name=$(echo -e "$final_device_list" | sed 's/^.* //g')
  if [[ $( echo "$paired_device_mac" | grep "$device_mac" ) =~ "$device_mac" ]]; then
      if [[ $( echo "$connected_device_mac"| grep "$device_mac" ) =~ "$device_mac" ]]; then 
        paired="Disconnect\nForget"
      else
        paired="Connect\nForget"
      fi
  else
    paired="Pair"
  fi
  
  if [[ $(bluetoothctl devices Trusted | sed -n 's/.*\(..:..:..:..:..:.. *\).*/\1/p' | grep "$device_mac") =~ "$device_mac" ]]; then
    trusted="Disable auto-connect"
  else
    trusted="Enable auto-connect"
  fi

  device_action=$(echo -e "$paired\n$trusted" | rofi -dmenu -i -p $device_name)
  if [[ "$device_action" =~ "Pair" ]]; then
    if bluetoothctl pair "$device_mac"; then
      if bluetoothctl connect "$device_mac"; then
          notify-send "Bluetooth Connection" "Paired and connectted to $device_name"
      else
          notify-send "Bluetooth Connection" "Paired but unable to connect to $device_name"
      fi
    else
      notify-send "Pairing failed with $device_name"
    fi
  elif [[ "$device_action" =~ "Connect to" ]]; then
    if bluetoothctl connect "$device_mac"; then
        notify-send "Bluetooth Connection" "Successfully connected to $device_name"
    else
        notify-send "Bluetooth Connection" "Failed to connect to $device_name"
    fi
  elif [[ "$device_action" =~ "Disconnect from" ]]; then
    bluetoothctl disconnect "$device_mac" && notify-send "Disconnected from $device_name"
  elif [[ "$device_action" =~ "Enable auto-connect" ]]; then
    bluetoothctl trust "$device_mac" && notify-send "Auto-connection enabled"
  elif [[ "$device_action" =~ "Disable auto-connect" ]]; then
    bluetoothctl untrust "$device_mac" && notify-send "Auto-connection disabled"
  elif [[ "$device_action" =~ "Forget" ]]; then
    bluetoothctl remove "$device_mac" && notify-send "$device_name forgotten"
  else
    notify-send "No action seleted"
  fi

else
  notify-send "No option selected"
fi
