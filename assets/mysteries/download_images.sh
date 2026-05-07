#!/bin/bash
# Joyful Mysteries
# 1. Annunciation
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Annunciation_%28Leonardo%29.jpg/800px-Annunciation_%28Leonardo%29.jpg" -o joyful_1.jpg &
# 2. Visitation
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Pontormo_-_Visitation_-_Detail.jpg/800px-Pontormo_-_Visitation_-_Detail.jpg" -o joyful_2.jpg &
# 3. Nativity
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Gerard_van_Honthorst_-_Adoration_of_the_Shepherds_-_Google_Art_Project.jpg/800px-Gerard_van_Honthorst_-_Adoration_of_the_Shepherds_-_Google_Art_Project.jpg" -o joyful_3.jpg &
# 4. Presentation
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Giovanni_Bellini_-_Presentation_at_the_Temple_-_Google_Art_Project.jpg/800px-Giovanni_Bellini_-_Presentation_at_the_Temple_-_Google_Art_Project.jpg" -o joyful_4.jpg &
# 5. Finding in the Temple
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Heinrich_Hoffmann_Finder_im_Tempel.jpg/800px-Heinrich_Hoffmann_Finder_im_Tempel.jpg" -o joyful_5.jpg &

# Sorrowful Mysteries
# 1. Agony in the Garden
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Giotto_-_Scrovegni_%28-16%29_-_Agony_in_the_Garden_%28detail%29.jpg/800px-Giotto_-_Scrovegni_%28-16%29_-_Agony_in_the_Garden_%28detail%29.jpg" -o sorrowful_1.jpg &
# 2. Scourging
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Scourging_of_Christ_by_Piero_della_Francesca.jpg/800px-Scourging_of_Christ_by_Piero_della_Francesca.jpg" -o sorrowful_2.jpg &
# 3. Crowning with Thorns
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Crowning_with_Thorns_by_Antonio_Correggio.jpg/800px-Crowning_with_Thorns_by_Antonio_Correggio.jpg" -o sorrowful_3.jpg &
# 4. Carrying the Cross
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/El_Greco_-_Christ_Carrying_the_Cross_-_Google_Art_Project.jpg/800px-El_Greco_-_Christ_Carrying_the_Cross_-_Google_Art_Project.jpg" -o sorrowful_4.jpg &
# 5. Crucifixion
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Van_der_Weyden_Crucifixion.jpg/800px-Van_der_Weyden_Crucifixion.jpg" -o sorrowful_5.jpg &

# Glorious Mysteries
# 1. Resurrection
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Piero_della_Francesca_075.jpg/800px-Piero_della_Francesca_075.jpg" -o glorious_1.jpg &
# 2. Ascension
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Giotto_-_Scrovegni_%28-18%29_-_Ascension.jpg/800px-Giotto_-_Scrovegni_%28-18%29_-_Ascension.jpg" -o glorious_2.jpg &
# 3. Descent of Holy Spirit
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ea/Titian_-_Pentecost_-_Google_Art_Project.jpg/800px-Titian_-_Pentecost_-_Google_Art_Project.jpg" -o glorious_3.jpg &
# 4. Assumption
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Titian_-_Assunta.jpg/800px-Titian_-_Assunta.jpg" -o glorious_4.jpg &
# 5. Coronation of Mary
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Vel%C3%A1zquez_-_Coronation_of_the_Virgin_-_Google_Art_Project.jpg/800px-Vel%C3%A1zquez_-_Coronation_of_the_Virgin_-_Google_Art_Project.jpg" -o glorious_5.jpg &

# Luminous Mysteries
# 1. Baptism
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Piero_della_Francesca_Baptism_of_Christ.jpg/800px-Piero_della_Francesca_Baptism_of_Christ.jpg" -o luminous_1.jpg &
# 2. Wedding at Cana
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Veronese_-_The_Wedding_at_Cana_-_Google_Art_Project.jpg/800px-Veronese_-_The_Wedding_at_Cana_-_Google_Art_Project.jpg" -o luminous_2.jpg &
# 3. Proclamation of Kingdom
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Giotto_-_Scrovegni_%28-08%29_-_Sermon_on_the_Mount.jpg/800px-Giotto_-_Scrovegni_%28-08%29_-_Sermon_on_the_Mount.jpg" -o luminous_3.jpg &
# 4. Transfiguration
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Raphael_-_Transfiguration_-_Google_Art_Project.jpg/800px-Raphael_-_Transfiguration_-_Google_Art_Project.jpg" -o luminous_4.jpg &
# 5. Institution of Eucharist
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Leonardo_da_Vinci_-_Last_Supper_%28copy%29.jpg/800px-Leonardo_da_Vinci_-_Last_Supper_%28copy%29.jpg" -o luminous_5.jpg &

wait
echo "All downloads complete"
ls -la *.jpg | wc -l
