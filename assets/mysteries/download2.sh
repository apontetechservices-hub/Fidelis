#!/bin/bash
# Joyful Mysteries
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c0/Annunciation_%28Leonardo%29.jpg/600px-Annunciation_%28Leonardo%29.jpg" -o joyful_1.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Pontormo_-_Visitation_-_Detail.jpg/600px-Pontormo_-_Visitation_-_Detail.jpg" -o joyful_2.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b4/Gerard_van_Honthorst_-_Adoration_of_the_Shepherds_-_Google_Art_Project.jpg/600px-Gerard_van_Honthorst_-_Adoration_of_the_Shepherds_-_Google_Art_Project.jpg" -o joyful_3.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Giovanni_Bellini_-_Presentation_at_the_Temple_-_Google_Art_Project.jpg/600px-Giovanni_Bellini_-_Presentation_at_the_Temple_-_Google_Art_Project.jpg" -o joyful_4.jpg 2>&1 &
# Finding in Temple - use a simpler URL
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Christ_found_in_the_temple.jpg/600px-Christ_found_in_the_temple.jpg" -o joyful_5.jpg 2>&1 &

# Sorrowful
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/Giotto_-_Scrovegni_%28-16%29_-_Agony_in_the_Garden_%28detail%29.jpg/600px-Giotto_-_Scrovegni_%28-16%29_-_Agony_in_the_Garden_%28detail%29.jpg" -o sorrowful_1.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Flagellation_of_Christ_by_Caravaggio.jpg/600px-Flagellation_of_Christ_by_Caravaggio.jpg" -o sorrowful_2.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Crowning_with_Thorns_Ecce_Homo_by_Antonio_Ciseri.jpg/600px-Crowning_with_Thorns_Ecce_Homo_by_Antonio_Ciseri.jpg" -o sorrowful_3.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/El_Greco_-_Christ_Carrying_the_Cross_-_Google_Art_Project.jpg/600px-El_Greco_-_Christ_Carrying_the_Cross_-_Google_Art_Project.jpg" -o sorrowful_4.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Die_Kreuzigung_Christi_%28Matthias_Gr%C3%BCnewald%29.jpg/600px-Die_Kreuzigung_Christi_%28Matthias_Gr%C3%BCnewald%29.jpg" -o sorrowful_5.jpg 2>&1 &

# Glorious
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/9/95/Piero_della_Francesca_075.jpg/600px-Piero_della_Francesca_075.jpg" -o glorious_1.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Giotto_-_Scrovegni_%28-18%29_-_Ascension.jpg/600px-Giotto_-_Scrovejni_%28-18%29_-_Ascension.jpg" -o glorious_2.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a6/Titian_-_Pentecost.jpg/600px-Titian_-_Pentocost.jpg" -o glorious_3.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Titian_-_Assunta.jpg/600px-Titian_-_Assunta.jpg" -o glorious_4.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Vel%C3%A1zquez_-_Coronation_of_the_Virgin_-_Google_Art_Project.jpg/600px-Vel%C3%A1zquez_-_Coronation_of_the_Virgin_-_Google_Art_Project.jpg" -o glorious_5.jpg 2>&1 &

# Luminous
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Piero_della_Francesca_Baptism_of_Christ.jpg/600px-Piero_della_Francesca_Baptism_of_Christ.jpg" -o luminous_1.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Veronese_-_The_Wedding_at_Cana_-_Google_Art_Project.jpg/600px-Veronese_-_The_Wedding_at_Cana_-_Google_Art_Project.jpg" -o luminous_2.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Giotto_-_Scrovegni_%28-08%29_-_Sermon_on_the_Mount.jpg/600px-Giotto_-_Scrovegni_%28-08%29_-_Sermon_on_the_Mount.jpg" -o luminous_3.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Raphael_-_Transfiguration_-_Google_Art_Project.jpg/600px-Raphael_-_Transfiguration_-_Google_Art_Project.jpg" -o luminous_4.jpg 2>&1 &
curl -sL "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Leonardo_da_Vinci_-_Last_Supper_%28copy%29.jpg/600px-Leonardo_da_Vinci_-_Last_Supper_%28copy%29.jpg" -o luminous_5.jpg 2>&1 &

wait
echo "Done"
for f in *.jpg; do
  echo "$f: $(file -b "$f" | head -c 30)"
done
