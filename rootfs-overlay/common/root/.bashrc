# Scripts propios en ~/bin
case ":$PATH:" in
    *":$HOME/bin:"*) ;;
    *) export PATH="$HOME/bin:$PATH" ;;
esac
