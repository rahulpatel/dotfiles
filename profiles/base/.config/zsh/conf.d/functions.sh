# functions - custom interactive zsh functions.
# Function files live in $ZDOTDIR/fns and are sourced in filename order.

for _fn in "$ZDOTDIR"/fns/*.sh(N); do
    source "$_fn"
done
unset _fn
