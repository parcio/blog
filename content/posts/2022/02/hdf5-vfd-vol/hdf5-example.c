#include <hdf5.h>

int main(int argc, char** agv) 
{
    // create a file and a group
    hid_t file_id = H5Fcreate("solution.h5", H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);
    hid_t group_id = H5Gcreate(file_id, "important_data", H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    // create and write to a dataset
    float important_numbers[3][3] = {{42, 42, 42}, 
                                     {42, 42, 42}, 
                                     {42, 42, 42.42}};
    hsize_t dims[2] = {3, 3};
    hsize_t* max_dims = dims;
    hid_t space_matrix_id = H5Screate_simple(2, dims, max_dims);

    hid_t set_id = H5Dcreate(group_id, "my_cool_data", H5T_NATIVE_FLOAT, space_matrix_id, 
                H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);
    H5Dwrite(set_id, H5T_NATIVE_FLOAT, space_matrix_id, space_matrix_id, 
                H5P_DEFAULT, &important_numbers);
    
    // create some attributes
    hid_t space_scalar_id = H5Screate(H5S_SCALAR);
    float mean = 42.05;
    char content_description[] = "Contains a dataset with the answer to everything!";

    hid_t string_type = H5Tcopy(H5T_C_S1);
    H5Tset_size(string_type, sizeof(content_description));

    hid_t attr_group = H5Acreate(group_id, "content", string_type, space_scalar_id, H5P_DEFAULT, H5P_DEFAULT);
    H5Awrite(attr_group, string_type, content_description);

    hid_t attr_set = H5Acreate(set_id, "mean", H5T_NATIVE_FLOAT, space_scalar_id, H5P_DEFAULT, H5P_DEFAULT);
    H5Awrite(attr_set, H5T_NATIVE_FLOAT, &mean);


    // close all objects
    H5Tclose(string_type);
    H5Dclose(set_id);
    H5Aclose(attr_group);
    H5Aclose(attr_set);
    H5Sclose(space_scalar_id);
    H5Sclose(space_matrix_id);
    H5Gclose(group_id);
    H5Fclose(file_id);
    return 0;
}