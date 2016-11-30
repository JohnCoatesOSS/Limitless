//
//  CancelStatus.hpp
//  Cydia
//
//  Created on 8/29/16.
//

class CancelStatus :
public pkgAcquireStatus
{
private:
    bool cancelled_;
    
public:
    CancelStatus() {
        // TODO: Figure out why this causes crash
//        cancelled_ = false;
    }
    
    virtual bool MediaChange(std::string media, std::string drive) {
        return false;
    }
    
    virtual void IMSHit(pkgAcquire::ItemDesc &desc) {
        Done(desc);
    }
    
    virtual bool Pulse_(pkgAcquire *Owner) = 0;
    
    virtual bool Pulse(pkgAcquire *Owner) {
        if (pkgAcquireStatus::Pulse(Owner) && Pulse_(Owner))
            return true;
        else {
            cancelled_ = true;
            return false;
        }
    }
    
    _finline bool WasCancelled() const {
        return cancelled_;
    }
};
