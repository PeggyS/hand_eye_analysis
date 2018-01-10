function y_val = get_y_val(xdata, ydata, x_val)

ind = find(xdata>=x_val, 1, 'first');

y_val = (ydata(ind+1)-ydata(ind))/(xdata(ind+1)-xdata(ind)) * (x_val-xdata(ind)) + ydata(ind);