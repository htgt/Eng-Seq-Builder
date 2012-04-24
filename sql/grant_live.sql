GRANT SELECT, INSERT, UPDATE, DELETE ON eng_seq_type TO eng_seq;
GRANT SELECT ON eng_seq_type TO eng_seq_ro;
GRANT SELECT, UPDATE ON eng_seq_type_id_seq TO eng_seq;

GRANT SELECT, INSERT, UPDATE, DELETE ON eng_seq TO eng_seq;
GRANT SELECT ON eng_seq TO eng_seq_ro;
GRANT SELECT, UPDATE ON eng_seq_id_seq TO eng_seq;

GRANT SELECT, INSERT, UPDATE, DELETE ON simple_eng_seq TO eng_seq;
GRANT SELECT ON simple_eng_seq TO eng_seq_ro;

GRANT SELECT, INSERT, UPDATE, DELETE ON compound_eng_seq_component TO eng_seq;
GRANT SELECT ON compound_eng_seq_component TO eng_seq_ro;

GRANT SELECT, INSERT, UPDATE, DELETE ON eng_seq_feature TO eng_seq;
GRANT SELECT ON eng_seq_feature TO eng_seq_ro;
GRANT SELECT, UPDATE ON eng_seq_feature_id_seq TO eng_seq;

GRANT SELECT, INSERT, UPDATE, DELETE ON eng_seq_feature_tag TO eng_seq;
GRANT SELECT ON eng_seq_feature_tag TO eng_seq_ro;
GRANT SELECT, UPDATE ON eng_seq_feature_tag_id_seq TO eng_seq;

GRANT SELECT, INSERT, UPDATE, DELETE ON eng_seq_feature_tag_value TO eng_seq;
GRANT SELECT ON eng_seq_feature_tag_value TO eng_seq_ro;
GRANT SELECT, UPDATE ON eng_seq_feature_tag_value_id_seq TO eng_seq;
