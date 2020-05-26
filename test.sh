read -p "生成订阅链接 (yes/no)? " linkConfirm
case "${linkConfirm}" in
  y|Y|[yY][eE][sS] ) continue ;;
  * ) echo "bye" && return 0;;
esac

echo "yes"