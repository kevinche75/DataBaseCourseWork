from datetime import datetime
from datetime import timedelta
import random

def str_time_prop(start, end, format, prop):
    
    stime = datetime.strptime(start, format)
    etime = datetime.strptime(end, format)

    ptime = stime + prop * (etime - stime)
    etime = ptime + timedelta(hours=random.randint(1, 12))

    return ptime.strftime(format), etime.strftime(format)


def random_date(start, end, prop, format):
    return str_time_prop(start, end, format, prop)