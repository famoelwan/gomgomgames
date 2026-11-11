-- Jumjum V5: seed the category registry and approved launch configuration.
-- Safe to re-run: existing category slugs and setting keys are left unchanged.
-- No question records or final stage rows are created by this migration.

INSERT OR IGNORE INTO categories
  (id, slug, name_ar, audience, is_active, sort_order)
VALUES
('general_sports','general_sports','الرياضة','general',1,1),
('general_science','general_science','العلوم','general',1,2),
('general_geography','general_geography','الجغرافيا','general',1,3),
('general_history_civilizations','general_history_civilizations','التاريخ والحضارات','general',1,4),
('general_religion_culture','general_religion_culture','الدين والثقافة الدينية','general',1,5),
('general_math','general_math','الرياضيات والحساب','general',1,6),
('general_language_literature','general_language_literature','اللغة والأدب','general',1,7),
('general_technology_inventions','general_technology_inventions','التكنولوجيا والاختراعات','general',1,8),
('general_culture_arts','general_culture_arts','الثقافة العامة والفنون','general',1,9),
('general_logic_intelligence','general_logic_intelligence','المنطق والذكاء','general',1,10),
('general_animals_nature','general_animals_nature','الحيوانات والطبيعة','general',1,11),
('general_economy_finance','general_economy_finance','الاقتصاد والثقافة المالية','general',1,12),
('babys_colors_shapes','babys_colors_shapes','الألوان والأشكال','babys',1,20),
('babys_numbers_fun_math','babys_numbers_fun_math','الأرقام والرياضيات الممتعة','babys',1,21),
('babys_animal_world','babys_animal_world','عالم الحيوانات','babys',1,22),
('babys_little_explorer','babys_little_explorer','المستكشف الصغير','babys',1,23),
('babys_emotions_social_intelligence','babys_emotions_social_intelligence','المشاعر والذكاء الاجتماعي','babys',1,24),
('babys_life_skills_safety','babys_life_skills_safety','المهارات الحياتية والسلامة','babys',1,25),
('babys_art_creativity_imagination','babys_art_creativity_imagination','الفن والإبداع والخيال','babys',1,26),
('babys_memory_focus','babys_memory_focus','الذاكرة والتركيز','babys',1,27),
('kids_colors_shapes','kids_colors_shapes','الألوان والأشكال','kids',1,30),
('kids_numbers_fun_math','kids_numbers_fun_math','الأرقام والرياضيات الممتعة','kids',1,31),
('kids_animal_world','kids_animal_world','عالم الحيوانات','kids',1,32),
('kids_little_explorer','kids_little_explorer','المستكشف الصغير','kids',1,33),
('kids_emotions_social_intelligence','kids_emotions_social_intelligence','المشاعر والذكاء الاجتماعي','kids',1,34),
('kids_life_skills_safety','kids_life_skills_safety','المهارات الحياتية والسلامة','kids',1,35),
('kids_art_creativity_imagination','kids_art_creativity_imagination','الفن والإبداع والخيال','kids',1,36),
('kids_memory_focus','kids_memory_focus','الذاكرة والتركيز','kids',1,37),
('juniors_colors_shapes','juniors_colors_shapes','الألوان والأشكال','juniors',1,40),
('juniors_numbers_fun_math','juniors_numbers_fun_math','الأرقام والرياضيات الممتعة','juniors',1,41),
('juniors_animal_world','juniors_animal_world','عالم الحيوانات','juniors',1,42),
('juniors_little_explorer','juniors_little_explorer','المستكشف الصغير','juniors',1,43),
('juniors_emotions_social_intelligence','juniors_emotions_social_intelligence','المشاعر والذكاء الاجتماعي','juniors',1,44),
('juniors_life_skills_safety','juniors_life_skills_safety','المهارات الحياتية والسلامة','juniors',1,45),
('juniors_art_creativity_imagination','juniors_art_creativity_imagination','الفن والإبداع والخيال','juniors',1,46),
('juniors_memory_focus','juniors_memory_focus','الذاكرة والتركيز','juniors',1,47);

INSERT OR IGNORE INTO game_settings (setting_key, setting_value)
VALUES
('content.launch_bank_total_questions','76000'),
('content.launch_bank_adult_questions','60000'),
('content.launch_bank_children_questions','16000'),
('content.launch_bank_reserve_questions','500'),
('content.adult_category_count','12'),
('content.child_category_count','8'),
('content.child_age_groups','["babys","kids","juniors"]'),
('content.child_categories_available_to_all_age_groups','true'),
('content.child_question_banks_separated_by_age','true'),
('stages.adventure_stage_count','200'),
('stages.operational_questions_total','8080'),
('stages.question_time_limit_seconds','30'),
('stages.star_thresholds','{"three_stars_min_percent":90,"two_stars_min_percent":70}'),
('stages.star_rewards','{"three_stars_achievement_points":6,"two_stars_achievement_points":3,"one_star_achievement_points":0}'),
('stages.final_stage_schedule_status','pending_review');
