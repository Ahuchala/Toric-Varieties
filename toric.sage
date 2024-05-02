# todo: - improve memory efficiency by storing rays instead of cones
#       - (probably an array)
#       - write faster isomoprhism check -- use more invariants?

use_macaulay = True

import itertools

# return the vector from p to q
def subtract_vertices(p,q):
    v1 = list(p)
    v2 = list(q)
    return [y-x for (x,y) in zip(v1,v2)]

# return the local cone of P at p
def local_cone(P,X,p):
    return Cone(rays= ([list(_) for _ in X.rays()] + [subtract_vertices(p,q) for q in P.vertices()]))

# returns sum of each linearly independent d-tuple of elements of B
def lin_indep_subsets(B,N,d):
    return_set = set()
    for tup in itertools.combinations(B,d):
#       check linear independence
        if (Matrix(tup).right_kernel().dimension() == N-d):   # this is an easy way to check linear independence
#           add elements componentwise
            return_set.add(tuple([sum([tup[i][j] for i in range(d)]) for j in range(N)]))
    return return_set

# In: a cone X
# Out: the list of rays of X (technically a tuple for hashing purposes)
def rays(X):
    return tuple([tuple([int(__) for __ in _]) for _ in X.rays()])

# In: a cone
# Out: a list of local cones of the Nash blowup of C
def blowup(C):
    # dimension of C
    c_cone = C
    c_rays = rays(C)
    
    N = c_cone.lattice().dimension()
    d = c_cone.dim()

    # hilbert basis of C, stored as lists
    list_basis = []
    if not use_macaulay:
        list_basis = [list(_) for _ in c_cone.Hilbert_basis()]
    else:
        eval_string = str([_[:] for _ in list(C.rays())]) #todo: update?
        eval_string = eval_string.replace('[','{')
        eval_string = eval_string.replace(']','}')
        eval_string = eval_string.replace('(','{')
        eval_string = eval_string.replace(')','}')

        R = macaulay2("m = transpose(matrix(" + eval_string + ")); C = posHull m; hilbertBasis C")

        list_basis = []
        for row in R:
            s = str(row.entries()).replace('}','').replace('{','').replace(',','').split(' ')
            list_basis.append([int(_) for _ in s])

    convex_hull = Polyhedron(lin_indep_subsets(list_basis,N,d))

    P = Polyhedron(rays=c_rays) + convex_hull

# pick a representative of each isomorphism class
    cone_dict = {}
    for p in P.vertices():
        new_cone = local_cone(P,C,p)
        new_cone_rays = rays(new_cone)
        new_cone_rays_len = len(new_cone_rays)
        seen = False
        for cone in cone_dict.keys():
            if new_cone_rays_len == len(rays(cone)):
                if new_cone.is_isomorphic(cone):
                    cone_dict[cone] = cone_dict[cone] + 1
                    seen = True
                    pass
        if not seen:
            cone_dict[new_cone] = 1
    print(len(c_rays), len(list_basis) )
    return cone_dict
# returns {cone} -> number


known_rays = [{} for _ in range(50)]

positive_orthant_cones = [0] +  [Cone(matrix.identity(_)) for _ in range(1,40)]

# checks if a given cone is isomorphic to a positive orthant under GL(d,Z) action
def is_trivial(C):
    d = len(rays(C))
    return C.is_isomorphic(positive_orthant_cones[d])

# this set hold the rays of all cones to be evaluated--blown up or looked up
ray_set = set()

def check_if_known(C):
    d = len(rays(C))
    for r in known_rays[d].keys():
        if C.is_isomorphic(Cone(r)):
            return True
    return False

# this does the heavy lifting
def compute_blowup_tree(C):
    ray_set.add(rays(C))
    first_step = True
    
    while len(ray_set) > 0:
        c_rays = ray_set.pop()
        c_cone = Cone(c_rays)
        first_step = True

        if not check_if_known(c_cone):
            if not first_step:
                if len(c_rays) == 10:
                    if c_cone.is_isomorphic(Xog):
                        print(c_cone,c_rays)
                        print("winner!")
                        return
            ls = blowup(c_cone)
            known_rays[len(c_rays)][c_rays] = ls
            for cone in ls.keys(): # double check this
                if not check_if_known(cone):
                    if not is_trivial(cone):
                        ray_set.add(rays(cone))
            first_step = False
                

# this assembles known information to return the full blowup tree
# need to call compute_blowup_tree first
# note: only contains one representative per isomorphism class of local cones
def print_blowup_tree(C,depth = 0):
    if depth == 0:
        print(list(C.rays()))
    ls = known_rays[len(rays(C))][rays(C)]
    for a in ls:
        print(str("  " * (depth+1)) + str(ls[a]) + " "+ str(list(a.rays())))
        if not is_trivial(a):
            print_blowup_tree(a,depth+1)
    return


# basis from https://pages.uoregon.edu/njp/MS.pdf

# m = Matrix(((1,0,0),(0,1,0),(1,1,3)))
m = Matrix([(0,0,0,0,0,1,1,1,1,1), (1,0,0,0,0,0,2,1,1,2), (0,1,0,0,0,2,0,2,1,1), (0,0,1,0,0,1,2,0,2,1), (0,0,0,1,0,1,1,2,0,2), (0,0,0,0,1,2,1,1,2,0)])
X = Cone(m).dual()
Xog = X


compute_blowup_tree(X)
print_blowup_tree(X)