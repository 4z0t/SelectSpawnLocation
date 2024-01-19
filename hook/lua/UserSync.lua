do
    local _OnSync = OnSync
    function OnSync()
        _OnSync()
        if Sync.Markers then
            import('/mods/SSL/modules/Markers.lua').UpdateMarkers(Sync.Markers)
        end

        if Sync.DeleteMarkers then
            import('/mods/SSL/modules/Markers.lua').Delete()
        end
    end
end
