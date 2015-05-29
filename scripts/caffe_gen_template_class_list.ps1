[regex]$r = '.*INSTANTIATE_CLASS\((.*)\).*'
$classes = dir *.cpp -Recurse | select-string -Pattern $r -AllMatches | % { $_.Matches } | % { $_.Groups[1].Value } 
[string]::Join(";", $classes)