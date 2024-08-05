#!/bin/bash
refresh=true


while ($refresh == true) 
do

  connected_device_list=$(bluetoothctl devices Connected | sed 's/Device //g' | sed 's/./ 󰂱  /18')
  connected_device_mac=$(echo "$connected_device_list" | sed 's/ .*//g' )
  paired_device_list=$(bluetoothctl devices Paired | sed 's/Device //g' | sed 's/./   /18')
  paired_device_mac=$(echo "$paired_device_list" |  sed 's/ .*//g' )
  
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

  device_selected=$(echo -e "$refresh_message" | sed 's/^..:..:..:..:..:.. //g' | rofi -replace -dmenu -i -selected-row 1 -p "Select a device") 

  if [[ "$device_selected" =~ " Refresh" ]]; then
    refresh=true
    notify-send "Refreshing..."
    bluetoothctl -t 3 scan on
  elif [[ "$device_selected" =~ "󰂯 Enable Bluetooth" ]]; then
    bluetooth on 
    notify-send "Bluetooth powered on"
    refresh=true
  else
    refresh=false
  fi

done

if [[ "$device_selected" =~ "󰂲 Disable Bluetooth" ]]; then
  bluetooth off
  notify-send "Bluetooth powered off"
elif [[ -n $device_selected ]]; then
  device_mac=$(echo -e "$final_device_list" | grep "$device_selected" | sed 's/ .*//g')
  device_name=$(echo -e "$final_device_list" | grep "$device_selected" | sed 's/^.* //g')
  echo $device_selected
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
    bluetoothctl pairable on
    if bluetoothctl pair "$device_mac"; then
      if bluetoothctl connect "$device_mac"; then
          notify-send "Bluetooth Connection" "Paired and connectted to $device_selected"
      else
          notify-send "Bluetooth Connection" "Paired but unable to connect to $device_selected"
      fi
    else
      notify-send "Pairing failed with $device_selected"
    fi
    bluetoothctl pairable off
  elif [[ "$device_action" =~ "Connect" ]]; then
    if bluetoothctl connect "$device_mac"; then
        notify-send "Bluetooth Connection" "Successfully connected to ${device_selected:3}"
    else
        notify-send "Bluetooth Connection" "Failed to connect to ${device_selected:3}"
    fi
  elif [[ "$device_action" =~ "Disconnect" ]]; then
    bluetoothctl disconnect "$device_mac" && notify-send "Disconnected from ${device_selected:3}"
  elif [[ "$device_action" =~ "Enable auto-connect" ]]; then
    bluetoothctl trust "$device_mac" && notify-send "Auto-connection enabled"
  elif [[ "$device_action" =~ "Disable auto-connect" ]]; then
    bluetoothctl untrust "$device_mac" && notify-send "Auto-connection disabled"
  elif [[ "$device_action" =~ "Forget" ]]; then
    bluetoothctl remove "$device_mac" && notify-send "${device_selected:3} forgotten"
  else
    notify-send "No action seleted"
  fi

else
  notify-send "No option selected"
fi
