# Binary Addition

This is a toy package on utilizing `pytorch` to teach a RNN binary addition task.
The addition task is to add several numbers represented in some base (not just binary, counterintuitively) strings.
For two binary numbers; it would look like;

```
15 + 27 = 42
( 15) 0 0 1 1 1 1
( 27) 0 1 1 0 1 1
(+__)------------
( 42) 1 0 1 0 1 0
```

The each n-ary digit is input starting from the lowest 
