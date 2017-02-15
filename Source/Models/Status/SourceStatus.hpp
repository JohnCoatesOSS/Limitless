//
//  SourceStatus.hpp
//  Cydia
//
//  Created on 8/29/16.
//

class SourceStatus :
public CancelStatus
{
private:
    _transient NSObject<FetchDelegate> *delegate_;
    _transient Database *database_;
    std::set<std::string> fetches_;
    
public:
    SourceStatus(NSObject<FetchDelegate> *delegate, Database *database) :
    delegate_(delegate),
    database_(database)
    {
    }
    
    void Set(bool fetch, const std::string &uri) {
        if (fetch) {
            if (!fetches_.insert(uri).second)
                return;
        } else {
            if (fetches_.erase(uri) == 0)
                return;
        }
        
        //printf("Set(%s, %s)\n", fetch ? "true" : "false", uri.c_str());
        auto slash(uri.rfind('/'));
        if (slash != std::string::npos) {
            [database_ setFetch:fetch forURI:uri.substr(0, slash).c_str()];
        }
    }
    
    _finline void Set(bool fetch, pkgAcquire::Item *item) {
        /*unsigned long ID(fetch ? 1 : 0);
         if (item->ID == ID)
         return;
         item->ID = ID;*/
        Set(fetch, item->DescURI());
    }
    
    void Log(const char *tag, pkgAcquire::Item *item) {
        //printf("%s(%s) S:%u Q:%u\n", tag, item->DescURI().c_str(), item->Status, item->QueueCounter);
    }
    
    virtual void Fetch(pkgAcquire::ItemDesc &desc) {
        Log("Fetch", desc.Owner);
        Set(true, desc.Owner);
    }
    
    virtual void Done(pkgAcquire::ItemDesc &desc) {
        Log("Done", desc.Owner);
        Set(false, desc.Owner);
    }
    
    virtual void Fail(pkgAcquire::ItemDesc &desc) {
        Log("Fail", desc.Owner);
        Set(false, desc.Owner);
    }
    
    virtual bool Pulse_(pkgAcquire *Owner) {
        std::set<std::string> fetches;
        for (pkgAcquire::ItemCIterator item(Owner->ItemsBegin()); item != Owner->ItemsEnd(); ++item) {
            bool fetch;
            if ((*item)->QueueCounter == 0)
                fetch = false;
            else switch ((*item)->Status) {
                case pkgAcquire::Item::StatFetching:
                    fetches.insert((*item)->DescURI());
                    fetch = true;
                    break;
                    
                default:
                    fetch = false;
                    break;
            }
            
            Log(fetch ? "Pulse<true>" : "Pulse<false>", *item);
            Set(fetch, *item);
        }
        
        std::vector<std::string> stops;
        std::set_difference(fetches_.begin(), fetches_.end(), fetches.begin(), fetches.end(), std::back_insert_iterator<std::vector<std::string>>(stops));
        for (std::vector<std::string>::const_iterator stop(stops.begin()); stop != stops.end(); ++stop) {
            //printf("Stop(%s)\n", stop->c_str());
            Set(false, *stop);
        }
        
        return ![delegate_ isSourceCancelled];
    }
    
    virtual void Stop() {
        pkgAcquireStatus::Stop();
        [database_ resetFetch];
    }
};
