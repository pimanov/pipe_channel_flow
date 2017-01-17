
# coding: utf-8

# In[55]:

import numpy as np
import math


# In[56]:

import matplotlib.pyplot as plt
get_ipython().magic(u'matplotlib inline')


# # Grid

# In[57]:

class Rrt:
    def __init__(self, y0, y01):
        yp = lambda a,b: 0.01 * math.sqrt(0.3*(b+1)) * (a*(58.*b-21.-21.*b*b)+100.)
        y1p = lambda a,b: 1. + a * (b - 0.45 * (b+1.)**2)
        dyda = lambda a,b: 0.01 * math.sqrt(0.3*(b+1)) * (58.*b - 21. - 21.*b*b)
        dydb = lambda a,b: 0.01 * math.sqrt(0.3*(b+1)) * (0.5 * (a*(58.*b - 21. - 21.*b*b) + 100.)/(b+1) + a*(58.-42*b))
        dy1da = lambda a,b: b - 0.45 * (b+1.)**2
        dy1db = lambda a,b: a * (1. - 0.9*(b+1.))

        a = 0.0
        b = 10. / 3.*y0*y0 - 1.

        while True:
            c1 = dyda(a,b)
            c2 = dydb(a,b)
            c3 = y0 - yp(a,b)
            c4 = dy1da(a,b)
            c5 = dy1db(a,b)
            c6 = y01 - y1p(a,b)
            d  = c1*c5 - c2*c4
            da = (c3*c5 - c2*c6) / d
            db = (c1*c6 - c3*c4) / d
            a = a + da
            b = b + db
            if abs(da) < 1.e-5 and abs(db) < 1.e-5: 
                break

        self.aset = a
        self.bset = b

    i0 = lambda self, x: x * (1. + self.aset * (1. - x**2) * (self.bset - x**2))
    i1 = lambda self, x: 1. + self.aset * (self.bset - 3.*(1.+self.bset)*x**2 + 5.*x**4)


# In[23]:

Xmax,Zmax,epsr,nsym = 4*[float("nan")]
xf,xn,hx,lx,Im = None, None, float('nan'), 0, 1
rn,yn,rt1,rf,yf,yt1,Jm = 6*[None] + [1]
thn,zn,thf,zf,ht,lt,Km = 4*[None] + [float('nan'), 0, 1]
Re, cf = 2*[float('nan')]


# In[24]:

def init_r():
    global rn, yn, rt1, rf, yf, yt1
    
    hr = 1.0 / Jm
    rrt = Rrt(1.0, epsr)

    ros = np.linspace(0, 1+hr, Jm+2)
    rn = np.array([rrt.i0(ro) for ro in ros])
    yn = 1.0 - rn
    rt1 = np.array([rrt.i1(ro)*hr for ro in ros])

    ros -= hr/2
    rf = np.array([rrt.i0(ro) for ro in ros])
    yf = 1.0 - rf
    yt1 = np.array([rrt.i1(ro)*hr for ro in ros])
    
    

def init_th():
    global thn, zn, thf, zf, ht, Km, Zmax
    
    Km = 2**lt
    Zmax = 2.4 / nsym
    ht = Zmax / Km
    thn = np.linspace(0, Zmax+ht, Km+2)
    zn = Zmax - thn
    thf = thn - 0.5*ht
    zf = Zmax - thf

def init_x():
    global xn, xf, hx, Im
    
    Im = 2**lx
    hx = Xmax / Im
    xn = np.linspace(0, Xmax+hx, Im+2)
    xf = xn - 0.5*hx

def __str__():
    ret = "## duct sym geometry module\n"
#    ret += "## characteristic units is R and Umax=2*Ubulk \n"
    ret += "Xmax * Ymax * Zmax = %f x %f x %f\n" % (Xmax, 1.0, Zmax)
    ret += "Im * Jm * Km = %d x %d x %d\n" % (Im,Jm,Km)
    ret += "epsr=%f, nsym=%f, hx=%f, ht=%f\n" % (epsr, nsym, hx, ht)
    ret += "Re=%f, cf=%f" % (Re, cf)
    return ret


# # Calc

# In[25]:

def mod_bc(vel):
        
    vel[:,:,:,0] = vel[:,:,:,-2]
    vel[:,:,:,-1] = vel[:,:,:,1]
    
    u,v,w = vel
    
    u[0,:,:] = u[1,:,:]
    u[-1,:,:] = u[-2,:,:]
    
    u[:,0,:] = u[:,1,:]
    u[:,-1,:] = - u[:,-2,:]

    v[:,0,:] = 0.0
    v[:,-2,:] = 0.0
    v[:,-1,:] = float('nan')
            
    v[0,:,:] = v[1,:,:]
    v[-1,:,:] = v[-2,:,:]

    w[0,:,:] = 0.0
    w[-2,:,:] = 0.0
    w[-1,:,:] = float('nan')

    w[:,0,:] = w[:,1,:]
    w[:,-1,:] = - w[:,-2,:]


# In[26]:

def get_om(vel):
    mod_bc(vel)
    u,v,w = vel
    
    om = np.zeros((3,Km+2,Jm+2,Im+2))
    ox,on,ot = om
    
    for i in range(1,Im+1):
        for j in range(0,Jm+1):
            for k in range(0,Km+1):
                w0 = w.T[i,j,k]
                w1 = w.T[i,j+1,k]
                v0 = v.T[i,j,k]
                v1 = v.T[i,j,k+1]
                ox.T[i,j,k] = (w1 - w0) / rt1[j] - (v1 - v0) / ht
                
    for k in range(0,Km+1):
        for j in range(1,Jm+1):
            for i in range(0,Im+1):
                u0 = u.T[i,j,k]
                u1 = u.T[i,j,k+1]
                w0 = w.T[i,j,k]
                w1 = w.T[i+1,j,k]
                on.T[i,j,k] = (u1 - u0) / ht - (w1 - w0) / hx
                
    for k in range(1,Km+1):
        for j in range(0,Jm+1):
            for i in range(0,Im+1):
                u0 = u.T[i,j,k]
                u1 = u.T[i,j+1,k]
                v0 = v.T[i,j,k]
                v1 = v.T[i+1,j,k]
                ot.T[i,j,k] = (v1 - v0) / hx - (u1 - u0) / rt1[j]
    
    return om


# In[27]:

def get_nl(vel, om):
    u,v,w = vel
    ox,on,ot = om
    velt = np.zeros((3,Km+2,Jm+2,Im+2))
    ut,vt,wt = velt
    
    for i in range(1,Im+1):
        for j in range(1,Jm+1):
            for k in range(1,Km+1):
                v0 = 0.5 * (v.T[i,j-1,k] + v.T[i+1,j-1,k])
                v1 = 0.5 * (v.T[i,j,k] + v.T[i+1,j,k])
                ot0 = rt1[j-1] * ot.T[i,j-1,k]
                ot1 = rt1[j] * ot.T[i,j,k]
                w0 = 0.5 * (w.T[i,j,k-1] + w.T[i+1,j,k-1])
                w1 = 0.5 * (w.T[i,j,k] + w.T[i+1,j,k])
                or0 = on.T[i,j,k-1]
                or1 = on.T[i,j,k]
                ut.T[i,j,k] = 0.5 * ((v0*ot0 + v1*ot1) / yt1[j] - (w0*or0 + w1*or1))
        
    for k in range(1,Km+1):
        for i in range(1,Im+1):
            for j in range(1,Jm):
                w0 = 0.5 * (w.T[i,j,k-1] + w.T[i,j+1,k-1])
                w1 = 0.5 * (w.T[i,j,k] + w.T[i,j+1,k])
                ox0 = ox.T[i,j,k-1]
                ox1 = ox.T[i,j,k]
                u0 = 0.5 * (u.T[i-1,j,k] + u.T[i-1,j+1,k])
                u1 = 0.5 * (u.T[i,j,k] + u.T[i,j+1,k])
                ot0 = ot.T[i-1,j,k]
                ot1 = ot.T[i,j,k]
                vt.T[i,j,k] = 0.5 * ((w0*ox0 + w1*ox1) - (u0*ot0 + u1*ot1))
        
            vt.T[i,Jm,k] = 0.0
            
    for k in range(1,Km+1):
        for j in range(1,Jm+1):
            for i in range(1,Im+1):
                u0 = 0.5 * (u.T[i-1,j,k] + u.T[i-1,j,k+1])
                u1 = 0.5 * (u.T[i,j,k] + u.T[i,j,k+1])
                or0 = on.T[i-1,j,k]
                or1 = on.T[i,j,k]
                v0 = 0.5 * (v.T[i,j-1,k] + v.T[i,j-1,k+1])
                v1 = 0.5 * (v.T[i,j,k] + v.T[i,j,k+1])
                ox0 = rt1[j-1] * ox.T[i,j-1,k]
                ox1 = rt1[j] * ox.T[i,j,k]
                wt.T[i,j,k] = 0.5 * ((u0*or0 + u1*or1) - (v0*ox0 + v1*ox1) / yt1[j])
                
    return velt


# In[28]:

def get_nl_part(vel,om):
    u,v,w = vel
    ox,on,ot = om
    
    vt1 = np.zeros((Km+2,Jm+2,Im+2))
    vt2 = np.zeros((Km+2,Jm+2,Im+2))
    wt1 = np.zeros((Km+2,Jm+2,Im+2))
    wt2 = np.zeros((Km+2,Jm+2,Im+2))
       
    for k in range(1,Km+1):
        for i in range(1,Im+1):
            for j in range(1,Jm):
                w0 = 0.5 * (w.T[i,j,k-1] + w.T[i,j+1,k-1])
                w1 = 0.5 * (w.T[i,j,k] + w.T[i,j+1,k])
                ox0 = ox.T[i,j,k-1]
                ox1 = ox.T[i,j,k]
                u0 = 0.5 * (u.T[i-1,j,k] + u.T[i-1,j+1,k])
                u1 = 0.5 * (u.T[i,j,k] + u.T[i,j+1,k])
                ot0 = ot.T[i-1,j,k]
                ot1 = ot.T[i,j,k]
                vt1.T[i,j,k] = -0.5 * (u0*ot0 + u1*ot1)
                vt2.T[i,j,k] = 0.5 * (w0*ox0 + w1*ox1)
        
            vt1.T[i,Jm,k] = 0.0
            vt2.T[i,Jm,k] = 0.0
            
    for k in range(1,Km+1):
        for j in range(1,Jm+1):
            for i in range(1,Im+1):
                u0 = 0.5 * (u.T[i-1,j,k] + u.T[i-1,j,k+1])
                u1 = 0.5 * (u.T[i,j,k] + u.T[i,j,k+1])
                or0 = on.T[i-1,j,k]
                or1 = on.T[i,j,k]
                v0 = 0.5 * (v.T[i,j-1,k] + v.T[i,j-1,k+1])
                v1 = 0.5 * (v.T[i,j,k] + v.T[i,j,k+1])
                ox0 = rt1[j-1] * ox.T[i,j-1,k]
                ox1 = rt1[j] * ox.T[i,j,k]
                wt1.T[i,j,k] = 0.5 * (u0*or0 + u1*or1)
                wt2.T[i,j,k] = -0.5 * (v0*ox0 + v1*ox1) / yt1[j]
                
    return vt1, vt2, wt1, wt2


# In[29]:

def get_cux(vel,om):
    u = vel[0]
    ox = om[0]
    
    cux = np.zeros((Km+2,Jm+2,Im+2))
    for k in range(1,Km):
        for j in range(1,Jm+1):
            for i in range(1,Im+1):
                cux.T[i,j,k] = - u.T[i-1:i+1, j:j+2, k:k+2].mean() * (ox.T[i+1,j,k] - ox.T[i-1,j,k]) / (2 * hx)

    cux.T[:,:,Km] = 0.0
    cux.T[:,:,0] = 0.0
    cux.T[:,Jm,:] = 0.0
    cux.T[:,0,:] = 0.0
    cux.T[0] = cux.T[-2]
    cux.T[-1] = cux.T[1]
    return cux


# In[30]:

def get_d1x(vel,om):
    u = vel[0]
    ox = om[0]
        
    d1x = np.zeros((Km+2,Jm+2,Im+2))
    for k in range(1,Km):
        for j in range(1,Jm+1):
            for i in range(1,Im+1):
                d1x.T[i,j,k] = ox.T[i,j,k] * (u.T[i,j:j+2,k:k+2].mean() - u.T[i-1,j:j+2,k:k+2].mean()) / hx

    
    d1x.T[:,:,Km] = 0.0
    d1x.T[:,:,0] = 0.0
    d1x.T[:,Jm,:] = 0.0
    d1x.T[:,0,:] = 0.0
    d1x.T[0] = d1x.T[-2]
    d1x.T[-1] = d1x.T[1]
    return d1x


# In[31]:

def get_ox(v,w):
    ox = np.zeros_like(v)

    for j in range(0,Jm+1):
        for k in range(0,Km+1):
            w0 = w[k,j]
            w1 = w[k,j+1]
            v0 = v[k,j]
            v1 = v[k+1,j]
            ox[k,j] = (w1 - w0) / rt1[j] - (v1 - v0) / ht
                
    return ox


# In[32]:

def get_nl_terms(vel,om):
    vt1, vt2, wt1, wt2 = get_nl_part(vel,om)
    
    ox1 = get_ox(vt1,wt1)
    ox2 = get_ox(vt2,wt2)
    
    cux = get_cux(vel,om)
    d1x = get_d1x(vel,om)
    
    dtx = ox1 - cux
    dtx[:,Jm] = 0.0
    dtx[0] = 0.0
    dtx[Km] = 0.0
    ctx = ox2 - d1x
    ctx[:,Jm] = 0.0
    ctx[0] = 0.0
    ctx[Km] = 0.0
    cxx = cux + d1x
    return cxx, ctx, dtx


# # Read/Write

# In[33]:

import pipe_pytools.tools as tools


# In[34]:

def init():
    init_x()
    init_r()
    init_th()


# In[35]:

def read_dcp(fname, is_cf_in=False):
    
    global cf,Re,Xmax,epsr,lx,Jm,lt,nsym
    t,dt,Dp,Re,Xmax,epsr,lx,Jm,lt,nsym,vel = tools.get_dcp(fname)
    
    if is_cf_in: 
        cf = Dp
        
    init()
    mod_bc(vel)
    
    return t,dt,vel


# In[36]:

def write_dcp(fname, t, dt, vel, is_cf_in=True):
    Dp = cf if is_cf_in else 0.0
    tools.put_dcp(fname, t, dt, Dp, Re, Xmax, epsr, lx, Jm, lt, nsym, vel)


# # Calc

# # Elementary

# In[37]:

def thmean(vel):
    VEL = np.empty_like(vel)
    VEL[:] = vel[1:-1].mean(0)
    return VEL


# In[38]:

def xmean(vel):
    VEL = np.empty_like(vel)
    VEL.T[:] = vel.T[1:-1].mean(0)
    return VEL


# In[39]:

def cs_mean(u):
    return ((u[1:-1].mean(0).T * rt1)[1:-1].sum(-1))


# # Plots

# In[40]:

def cs_contourf_plot(u, yzloc="ff", *args, **kwargs):
    if yzloc[0] == 'f':
        y = yf.copy()
        y[-1] = 0.0
        y[0] = 1.0
    else:
        y = yn[:-1].copy()
        u = u[:,:-1]
        
    if yzloc[1] == 'f':
        th = thf.copy()
        th[0] = 0.0
        th[-1] = Zmax
    else:
        th = thn[:-1].copy()
        u = u[:-1,:]
        
    plt.contourf(th, y, u.T, *args, **kwargs)
    plt.xlim(-math.sqrt(2)/2 + 0.5, math.sqrt(2)/2 + 0.5)
    #plt.xlim(0,1)
    plt.ylim(0,1)
    ax = plt.gca()
    ax.xaxis.set_major_locator(plt.NullLocator())
    ax.yaxis.set_major_locator(plt.NullLocator())
    ax.set_aspect('equal')
    ax.axis('off')


# In[ ]:

def cs_contour_plot(u, yzloc="ff", *args, **kwargs):
    if yzloc[0] == 'f':
        y = yf.copy()
        y[-1] = 0.0
        y[0] = 1.0
    else:
        y = yn[:-1].copy()
        u = u[:,:-1]
        
    if yzloc[1] == 'f':
        th = thf.copy()
        th[0] = 0.0
        th[-1] = Zmax
    else:
        th = thn[:-1].copy()
        u = u[:-1,:]
        
    plt.contour(th, y, u.T, *args, **kwargs)
    plt.xlim(-math.sqrt(2)/2 + 0.5, math.sqrt(2)/2 + 0.5)
    #plt.xlim(0,1)
    plt.ylim(0,1)
    ax = plt.gca()
    ax.xaxis.set_major_locator(plt.NullLocator())
    ax.yaxis.set_major_locator(plt.NullLocator())
    ax.set_aspect('equal')
    ax.axis('off')


# In[20]:

def cs_arrows_plot((v,w), (dj,dk)=(3,3), ll=3, *args, **kwargs):
    for k in range(1, Km+1, dk):
        for j in range(1, Jm+1, dj):
            vy = - 0.5 * (v[k+1,j] + v[k,j]) * ll
            vx = 0.5 * (w[k,j+1] + w[k,j]) * ll
            plt.arrow(thn[k], yn[j], vx, vy, *args, **kwargs)


# In[76]:

def aplot(n):
    a = np.loadtxt("a0.dat", usecols=[0,n], unpack=True)
    plt.plot(a[0],a[1])


# In[96]:

def get_xmeans(vel):
    U,V,W = VEL = vel.T[1:-1].mean(0).T
    vel1T = vel.T - VEL.T
    
    vel1T[:,0,:,1] = 0.0
    vel1T[:,Jm,:,1] = 0.0
    vel1T[:,:,0,2] = 0.0
    vel1T[:,:,Km,2] = 0.0
    
    puls = np.zeros_like(U)
    for k in range(1,Km+1):
        for j in range(1,Jm+1):
            for i in range(1,Im+1):
                puls[k,j] += vel1T[i,j,k,0]**2 +                 0.25*(vel1T[i,j-1,k,1] + vel1T[i,j,k,1])**2 +                 0.25*(vel1T[i,j,k-1,2] + vel1T[i,j,k,2])**2
    puls /= Im
    puls **= 0.5
    
    puls[0,:] = puls[1,:]
    puls[-1,:] = puls[-2,:]
    puls[:,0] = puls[:,1]
    puls[:,-1] = - puls[:,-2]
    return U,V,W,puls


# In[97]:

def xmeans_plot(vel):
    U,V,W,P = get_xmeans(vel)
    OX = get_ox(V,W)
    
    plt.subplot(1,3,1)
    umax = U[1:-1,1:-1].max()
    cs_contourf_plot(U, "ff", np.linspace(0, 1, 21))
    plt.xlabel("U, max=%f" % umax, fontsize=14)
    
    plt.subplot(1,3,2)
    oxm = OX[1:-1,1:-1].max()
    cs_contourf_plot(OX, "nn", np.linspace(-oxm, oxm, 21))
    plt.xlabel("OX, max=%f" % oxm, fontsize=14)
    
    plt.subplot(1,3,3)
    pm = P[1:-1,1:-1].max()
    cs_contourf_plot(P, "nn", np.linspace(0, pm, 21))
    plt.xlabel("puls, max=%f" % pm, fontsize=14)


# # Calc

# In[1]:

def MPI_calc_init():
    pass


# In[79]:

def MPI_calc(vel, t1, dtmax, t2=0, dt=0, kprt=1, kwrt=10000, tol=0.01, 
             cpfn="tmp.dcp", prtfn="a0.dat", np=4, run_file="duct.out"):
    if t2:
        t = t1
        tmax = t2
    else:
        t = 0.0
        tmax = t1
        get_ipython().system(u'rm -f $prtfn')
        
    if not dt:
        dt = dtmax
    
    if cf != cf: 
        Exception("cf is nan")
        
    write_dcp(cpfn, t, dt, vel)
    tools.put_car(tmax, dt, cf, cpfn, tol=tol, kprt=kprt, kwrt=kwrt, prtfn=prtfn, fname="duct.car")
    comand = "mpirun -np %d ./%s" % (np, run_file)
    get_ipython().system(u'$comand')
    t,dt,vel = read_dcp(cpfn)
    
    return t,dt,vel


# In[ ]:



