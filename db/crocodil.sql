drop table trils;
create table trils (
    id int auto_increment,
    name varchar(255) not null,
    byte_size int,
    content_type varchar(255),
    created_on datetime,
    updated_on datetime,
    trilu_user varchar(255),
    trilu_file_id varchar(255),
    PRIMARY KEY(id)
);
    